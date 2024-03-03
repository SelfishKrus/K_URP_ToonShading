using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using GraphicsFormat = UnityEngine.Experimental.Rendering.GraphicsFormat;
using SerializableAttribute = System.SerializableAttribute;
using System.Collections.Generic;
using UnityEngine.Rendering.Universal;
using UnityEngine.Experimental.GlobalIllumination;

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

        [Range(1,4)]
        public int downSample = 2;
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
        if (renderingData.cameraData.camera.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(m_RenderPass);
            m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Color);
            m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Normal);
        }

    }

    public override void SetupRenderPasses(ScriptableRenderer renderer,
                                        in RenderingData renderingData)
    {

    }

    protected override void Dispose(bool disposing)
    {   
        base.Dispose(disposing);
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

        const int MaxMipMapLevel = 16;
        (RTHandle down, RTHandle up)[] mips = new (RTHandle down, RTHandle up) [MaxMipMapLevel];

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

            Dispose();

            var camDesc = renderingData.cameraData.cameraTargetDescriptor;
            camDesc.colorFormat = RenderTextureFormat.ARGB32;
            camDesc.depthBufferBits = 0;

            // set target
            m_cameraColorTarget = renderingData.cameraData.renderer.cameraColorTargetHandle;

            // Set up temporary color buffer (for blit)
            RenderingUtils.ReAllocateIfNeeded(ref rtTempColor0, camDesc, name: "_RTTempColor0");
            RenderingUtils.ReAllocateIfNeeded(ref rtTempColor1, camDesc, name: "_RTTempColor1");

            m_material = m_settings.material;

            ConfigureTarget(m_cameraColorTarget);
            ConfigureTarget(rtTempColor0);
            ConfigureTarget(rtTempColor1);
        
            // initialize mipmap chain
            var width = camDesc.width / m_settings.downSample;
            var height = camDesc.height / m_settings.downSample;
            camDesc.colorFormat = RenderTextureFormat.DefaultHDR;

            camDesc.width = width;
            camDesc.height = height;
            RenderingUtils.ReAllocateIfNeeded(ref mips[0].down, camDesc, name: "_RTMipDown0");

            for (int i = 1; i < MaxMipMapLevel; i++)
            {
                width /= 2;
                if ( width < 4) 
                {
                    mips[i] = (null, null);
                }
                else
                {   
                    camDesc.width = width;
                    camDesc.height = height;

                    RenderingUtils.ReAllocateIfNeeded(ref mips[i].down, camDesc, name: "_RTMipDown" + i);
                    RenderingUtils.ReAllocateIfNeeded(ref mips[i].up, camDesc, name: "_RTMipUp" + i);
                }
            }
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_material == null)
                return;

            if (m_cameraColorTarget.rt == null)
                return;

            CommandBuffer cmd = CommandBufferPool.Get("");
            using (UnityEngine.Rendering.ProfilingScope profilingScope = new UnityEngine.Rendering.ProfilingScope(cmd, m_profilingSampler))
            {   
                MaterialPropertyBlock s_PropertyBlock = new MaterialPropertyBlock();

                m_material.SetTexture("_CamColTex", m_cameraColorTarget);

                // Prefilter
                // CameraColorTarget -> Prefilter -> MIP 0
                Blitter.BlitCameraTexture(cmd, m_cameraColorTarget, mips[0].down, m_material, 0);

                // Downsample
                int level = 1;
                for (; level < MaxMipMapLevel && mips[level].down != null; level++)
                {   
                    Blitter.BlitCameraTexture(cmd, mips[level - 1].down, mips[level].down, m_material, 1);
                }

                // Upsample
                var lastRT = mips[--level].down;
                for (level--; level >= 0 && mips[level].up != null; level--)
                {
                    var mip = mips[level];
                    m_material.SetTexture("_HighTex", mip.down);
                    Blitter.BlitCameraTexture(cmd, lastRT, mip.up, m_material, 2);
                    lastRT = mip.up;
                }

                // Final composition
                Blitter.BlitCameraTexture(cmd, lastRT, m_cameraColorTarget, m_material, 3);

            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {   
            base.OnCameraCleanup(cmd);
            Dispose();
        }

        public void Dispose()
        {   
            if (rtTempColor0 != null) rtTempColor0.Release();
            if (rtTempColor1 != null) rtTempColor1.Release();

            for (int i = 0; i < MaxMipMapLevel; i++)
            {
                if (mips[i].down != null) mips[i].down.Release();
                if (mips[i].up != null) mips[i].up.Release();
            }
        }

        #region PRIVATE_METHODS

        #endregion
    }

}