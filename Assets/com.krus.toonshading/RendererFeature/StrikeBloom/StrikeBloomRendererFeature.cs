using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using GraphicsFormat = UnityEngine.Experimental.Rendering.GraphicsFormat;
using SerializableAttribute = System.SerializableAttribute;
using System.Collections.Generic;
using UnityEngine.Rendering.Universal;

internal class StrikeBloomRendererFeature : ScriptableRendererFeature
{   

    //////////////
    // Settings // 
    //////////////

    [System.Serializable]
    public class StrkeBloomSettings 
    {   
        [Header("Render Pass")]
        public Material material;
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public string colorTargetDestinationID = "_CamColTex";

        public float threshold = 1.0f;
    }

    //////////////////////
    // Renderer Feature // 
    //////////////////////

    public StrkeBloomSettings settings = new StrkeBloomSettings();

    Material m_Material;

    StrkeBloomRenderPass m_RenderPass = null;

    public override void Create()
    {
        m_RenderPass = new StrkeBloomRenderPass(settings);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer,
                                    ref RenderingData renderingData)
    {
        // if (renderingData.cameraData.camera.cameraType != CameraType.Game && renderingData.cameraData.camera.cameraType != CameraType.SceneView)
            renderer.EnqueuePass(m_RenderPass);
            m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Color);
            m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Normal);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer,
                                        in RenderingData renderingData)
    {

    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(m_Material);
        m_RenderPass.Dispose();
    }

    //////////////////////
    //   Renderer Pass  // 
    //////////////////////

    internal class StrkeBloomRenderPass : ScriptableRenderPass
    {   
        ProfilingSampler m_profilingSampler = new ProfilingSampler("Outline");
        Material m_material;
        RTHandle m_cameraColorTarget;
        RTHandle rtCustomColor, rtTempColor;
        StrkeBloomSettings m_settings;

        public StrkeBloomRenderPass(StrkeBloomSettings settings)
        {   
            m_material = settings.material;
            this.m_settings = settings;
            renderPassEvent = m_settings.renderPassEvent;
        }

        public void SetTarget(RTHandle colorHandle)
        {
            m_cameraColorTarget = colorHandle;
        }

        // Pass Data //
        public void PassShaderData(Material material)
        {
            material.SetFloat("_Threshold", m_settings.threshold);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {   
            var colorDesc = renderingData.cameraData.cameraTargetDescriptor;
            colorDesc.colorFormat = RenderTextureFormat.ARGB32;
            colorDesc.depthBufferBits = 0;

            var renderer = renderingData.cameraData.renderer;
            // set target
            m_cameraColorTarget = renderer.cameraColorTargetHandle;

            // Set up temporary color buffer (for blit)

            RenderingUtils.ReAllocateIfNeeded(ref rtCustomColor, colorDesc, name: "_RTCustomColor");
            RenderingUtils.ReAllocateIfNeeded(ref rtTempColor, colorDesc, name: "_RTTempColor");

            ConfigureTarget(m_cameraColorTarget);
            ConfigureTarget(rtCustomColor);
            ConfigureTarget(rtTempColor);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cameraData = renderingData.cameraData;
            

            if (m_material == null)
                return;

            if (m_cameraColorTarget.rt == null)
                return;

            PassShaderData(m_material);

            CommandBuffer cmd = CommandBufferPool.Get();
            using (UnityEngine.Rendering.ProfilingScope profilingScope = new UnityEngine.Rendering.ProfilingScope(cmd, m_profilingSampler))
            {   
                // Prefilter
                m_material.SetTexture("_CamColTex", m_cameraColorTarget);
                Blitter.BlitCameraTexture(cmd, m_cameraColorTarget, rtCustomColor, m_material, 0);

                // Downsample
                m_material.SetTexture("_InputTex", rtCustomColor);
                Blitter.BlitCameraTexture(cmd, rtCustomColor, rtTempColor, m_material, 1);

                Blitter.BlitCameraTexture(cmd, rtTempColor, m_cameraColorTarget);
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            CommandBufferPool.Release(cmd);

        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {

        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            base.FrameCleanup(cmd);

        }

        public void Dispose()
        {

        }
    }

    #region Image pyramid class used in Streak effect

    sealed class StreakPyramid
    {
        public const int MaxMipLevel = 16;

        int _baseWidth, _baseHeight;
        readonly (RTHandle down, RTHandle up) [] _mips = new (RTHandle, RTHandle) [MaxMipLevel];

        public (RTHandle down, RTHandle up) this [int index]
        {
            get { return _mips[index]; }
        }

        public StreakPyramid(Camera camera)
        {
            Allocate(camera);
        }

        public bool CheckSize(Camera camera)
        {
            return _baseWidth == camera.pixelWidth && _baseHeight == camera.pixelHeight;
        }

        public void Reallocate(Camera camera)
        {
            Release();
            Allocate(camera);
        }

        public void Release()
        {
            foreach (var mip in _mips)
            {
                if (mip.down != null) RTHandles.Release(mip.down);
                if (mip.up   != null) RTHandles.Release(mip.up);
            }
        }

        void Allocate(Camera camera)
        {
            _baseWidth = camera.pixelWidth;
            _baseHeight = camera.pixelHeight;

            var width = _baseWidth;
            var height = _baseHeight / 2;

            const GraphicsFormat RTFormat = GraphicsFormat.R16G16B16A16_SFloat;

            _mips[0] = (RTHandles.Alloc(width, height, colorFormat: RTFormat), null);

            for (var i = 1; i < MaxMipLevel; i++)
            {
                width /= 2;
                _mips[i] = width < 4 ?  (null, null) :
                    (RTHandles.Alloc(width, height, colorFormat: RTFormat),
                     RTHandles.Alloc(width, height, colorFormat: RTFormat));
            }
        }
    }

    #endregion
}