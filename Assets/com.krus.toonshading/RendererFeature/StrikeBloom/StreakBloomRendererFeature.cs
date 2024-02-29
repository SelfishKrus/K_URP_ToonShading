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

        public float threshold = 1.0f;
        public float stretch = 1.0f;
        public float intensity = 1.0f;
        public Color color = new Color(1.0f, 1.0f, 1.0f);
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
        CoreUtils.Destroy(m_Material);
        m_RenderPass.Dispose();
    }

    //////////////////////
    //   Renderer Pass  // 
    //////////////////////

    internal class StreakBloomRenderPass : ScriptableRenderPass
    {   
        ProfilingSampler m_profilingSampler = new ProfilingSampler("Outline");
        Material m_material;
        RTHandle m_cameraColorTarget;
        RTHandle rtCustomColor, rtTempColor;
        StreakBloomSettings m_settings;

        public StreakBloomRenderPass(StreakBloomSettings settings)
        {   
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
            material.SetFloat("_Stretch", m_settings.stretch);
            material.SetFloat("_Intensity", m_settings.intensity);
            material.SetVector("_Color", m_settings.color);
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

            m_material = m_settings.material;
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

                Blitter.BlitCameraTexture(cmd, rtCustomColor, m_cameraColorTarget);
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            CommandBufferPool.Release(cmd);

        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            base.OnCameraCleanup(cmd);
            cmd.ReleaseTemporaryRT(rtCustomColor.GetInstanceID());
            cmd.ReleaseTemporaryRT(rtTempColor.GetInstanceID());
            cmd.ReleaseTemporaryRT(m_cameraColorTarget.GetInstanceID());
        }

        public void Dispose()
        {
            RTHandles.Release(rtCustomColor);
            RTHandles.Release(rtTempColor);
        }

        // Pyramid to store images
        Dictionary<int, StreakPyramid> _pyramids;

        StreakPyramid GetPyramid(Camera camera)
        {
            StreakPyramid candid;
            var cameraID = camera.GetInstanceID();

            if (_pyramids.TryGetValue(cameraID, out candid))
            {
                // Reallocate the RTs when the screen size was changed.
                if (!candid.CheckSize(camera)) candid.Reallocate(camera);
            }
            else
            {
                // No one found: Allocate a new pyramid.
                _pyramids[cameraID] = candid = new StreakPyramid(camera);
            }

            return candid;
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