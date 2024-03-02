using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using GraphicsFormat = UnityEngine.Experimental.Rendering.GraphicsFormat;
using SerializableAttribute = System.SerializableAttribute;
using System.Collections.Generic;
using UnityEngine.Rendering.Universal;

internal class StreakBloomRendererFeature : ScriptableRendererFeature
{   

    //////////////
    // Settings // 
    //////////////

    [System.Serializable]
    public class StreakBloomSettings 
    {   
        [Header("Render Pass")]
        public Material material;
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public string colorTargetDestinationID = "_CamColTex";
    }

    //////////////////////
    // Renderer Feature // 
    //////////////////////

    public StreakBloomSettings settings = new StreakBloomSettings();

    Material m_Material;

    StreakBloomRenderPass m_RenderPass = null;

    public override void Create()
    {
        m_RenderPass = new StreakBloomRenderPass(settings);
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
        m_RenderPass.Dispose();
    }

    //////////////////////
    //   Renderer Pass  // 
    //////////////////////

    internal class StreakBloomRenderPass : ScriptableRenderPass
    {   
        ProfilingSampler m_profilingSampler = new ProfilingSampler("StreakBloom");
        Material m_material;
        RTHandle m_cameraColorTarget;
        RTHandle rtTempColor0, rtTempColor1;
        StreakBloomSettings m_settings;

        StreakPyramid pyramid;

        public StreakBloomRenderPass(StreakBloomSettings settings)
        {   
            this.m_settings = settings;
            renderPassEvent = m_settings.renderPassEvent;
        }

        public void SetTarget(RTHandle colorHandle)
        {
            m_cameraColorTarget = colorHandle;
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

            RenderingUtils.ReAllocateIfNeeded(ref rtTempColor0, colorDesc, name: "_RTTempColor0");
            RenderingUtils.ReAllocateIfNeeded(ref rtTempColor1, colorDesc, name: "_RTTempColor1");

            m_material = m_settings.material;

            ConfigureTarget(m_cameraColorTarget);
            ConfigureTarget(rtTempColor0);
            ConfigureTarget(rtTempColor1);
        
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_material == null)
                return;

            if (m_cameraColorTarget.rt == null)
                return;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (UnityEngine.Rendering.ProfilingScope profilingScope = new UnityEngine.Rendering.ProfilingScope(cmd, m_profilingSampler))
            {   

                m_material.SetTexture("_CamColTex", m_cameraColorTarget);
                // pyramid = GetPyramid(renderingData.cameraData.camera);

                // Prefilter
                // CameraColorTarget -> Prefilter -> MIP 0
                // Blitter.BlitCameraTexture(cmd, m_cameraColorTarget, pyramid[0].down, m_material, 0);
                // Blitter.BlitCameraTexture(cmd, pyramid[0].down, m_cameraColorTarget);
                
                Blitter.BlitCameraTexture(cmd, m_cameraColorTarget, rtTempColor0, m_material, 0);
                Blitter.BlitCameraTexture(cmd, rtTempColor0, m_cameraColorTarget);

            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            CommandBufferPool.Release(cmd);

        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }

        public void Dispose()
        {   
            if (rtTempColor0 != null) RTHandles.Release(rtTempColor0);
            if (rtTempColor1 != null) RTHandles.Release(rtTempColor1);

            if (pyramid != null) pyramid.Release();
        }

        // Pyramid to store images
        Dictionary<int, StreakPyramid> _pyramids;

        StreakPyramid GetPyramid(Camera camera)
        {
            StreakPyramid candid;
            candid = new StreakPyramid(camera);
            
            return candid;
        }
    }

    #region Image pyramid class used in Streak effect

    sealed class StreakPyramid
    {
        public const int MaxMipLevel = 8;

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
            return _baseWidth == camera.scaledPixelWidth && _baseHeight == camera.scaledPixelHeight;
        }

        public void Reallocate(Camera camera)
        {
            Release();
            Allocate(camera);
        }

        public void ConfigureTarget(ScriptableRenderPass renderPass)
        {
            foreach (var mip in _mips)
            {
                if (mip.down != null) renderPass.ConfigureTarget(mip.down);
                if (mip.up   != null) renderPass.ConfigureTarget(mip.up);
            }
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
            _baseWidth = camera.scaledPixelWidth;
            _baseHeight = camera.scaledPixelHeight;

            var width = _baseWidth / 2;
            var height = _baseHeight / 4;

            const GraphicsFormat RTFormat = GraphicsFormat.R16G16B16A16_SFloat;

            _mips[0] = (RTHandles.Alloc(width, height, colorFormat: RTFormat), null);

            for (int i = 1; i < MaxMipLevel; i++)
            {
                width = Mathf.Max(1, width / 2);
                height = Mathf.Max(1, height / 2);

                var desc = new RenderTextureDescriptor(width, height, RenderTextureFormat.ARGBHalf, 0, MaxMipLevel)
                {
                    useMipMap = true,
                    autoGenerateMips = false,
                    enableRandomWrite = true
                };

                _mips[i].down = RTHandles.Alloc(desc);
                _mips[i].up = RTHandles.Alloc(desc);
            }
        }
    }

    #endregion
}