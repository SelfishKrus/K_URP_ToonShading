using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

internal class OutlineRendererFeature : ScriptableRendererFeature
{   

    //////////////
    // Settings // 
    //////////////

    [System.Serializable]
    public class OutlineSettings 
    {   
        [Header("Render Pass")]
        public Material material;
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public string colorTargetDestinationID = "_CamColTex";

        // [Header("Depth Outline")]
        // public bool enableDepthOutline = true;
        // [Range(0.0f, 1.0f)]
        // public float depthThreshold = 0.5f;
        // [Range(0.0f, 0.03f)]
        // public float depthThickness = 0.01f;
        // [Range(0.0f, 1.0f)]
        // public float depthSmoothness = 0.0f;
        // public Color depthOutlineColor = Color.black;

        // [Header("Normal Outline")]
        // public bool enableNormalOutline = true;
        // [Range(0.0f, 1.0f)]
        // public float normalThreshold = 0.5f;
        // [Range(0.0f, 0.03f)]
        // public float normalThickness = 0.01f;
        // [Range(0.0f, 1.0f)]
        // public float normalSmoothness = 0.0f;
        // public Color normalOutlineColor = Color.black;
        
    }

    //////////////////////
    // Renderer Feature // 
    //////////////////////

    public OutlineSettings settings = new OutlineSettings();

    Material m_Material;

    DepthOutlineRenderPass m_RenderPass = null;

    

    public override void Create()
    {
        m_RenderPass = new DepthOutlineRenderPass(settings);
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
        // if (renderingData.cameraData.camera.cameraType != CameraType.Game && renderingData.cameraData.camera.cameraType != CameraType.SceneView)
        // {
            m_RenderPass.SetTarget(renderer.cameraColorTargetHandle);
        // }
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(m_Material);
        m_RenderPass.Dispose();
    }

    //////////////////////
    //   Renderer Pass  // 
    //////////////////////

    internal class DepthOutlineRenderPass : ScriptableRenderPass
    {   
        ProfilingSampler m_profilingSampler = new ProfilingSampler("Outline");
        Material m_material;
        RTHandle m_cameraColorTarget;
        RTHandle rtCustomColor, rtTempColor;
        OutlineSettings m_settings;

        public DepthOutlineRenderPass(OutlineSettings settings)
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
            // if (m_settings.enableDepthOutline)
            // {
                // material.EnableKeyword("_DEPTH_OUTLINE");
            // }
            // material.SetFloat("_Depth_Threshold", m_settings.depthThreshold);
            // material.SetFloat("_Depth_Thickness", m_settings.depthThickness);
            // material.SetFloat("_Depth_Smoothness", m_settings.depthSmoothness);
            // material.SetVector("_Depth_OutlineColor", m_settings.depthOutlineColor);

            // if (m_settings.enableNormalOutline)
            // {
            //     material.EnableKeyword("_NORMAL_OUTLINE");
            // }
            // material.SetFloat("_Normal_Threshold", m_settings.normalThreshold);
            // material.SetFloat("_Normal_Thickness", m_settings.normalThickness);
            // material.SetFloat("_Normal_Smoothness", m_settings.normalSmoothness);
            // material.SetVector("_Normal_OutlineColor", m_settings.normalOutlineColor);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {   
            var colorDesc = renderingData.cameraData.cameraTargetDescriptor;
            colorDesc.depthBufferBits = 0;

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

            CommandBuffer cmd = CommandBufferPool.Get();
            using (UnityEngine.Rendering.ProfilingScope profilingScope = new UnityEngine.Rendering.ProfilingScope(cmd, m_profilingSampler))
            {
                PassShaderData(m_material);
                m_material.SetTexture(m_settings.colorTargetDestinationID, m_cameraColorTarget);

                RTHandle rtCamera = renderingData.cameraData.renderer.cameraColorTargetHandle;

                Blitter.BlitCameraTexture(cmd, m_cameraColorTarget, rtCustomColor, m_material, 0);
                Blitter.BlitCameraTexture(cmd, rtCustomColor, m_cameraColorTarget);
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
            // rtCustomColor.Release();
            // rtTempColor.Release();
        }

        public void Dispose()
        {
            rtCustomColor.Release();
            rtTempColor.Release();
        }
    }
}