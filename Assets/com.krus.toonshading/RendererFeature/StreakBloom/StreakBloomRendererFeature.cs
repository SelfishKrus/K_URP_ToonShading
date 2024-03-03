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
        
            // initialize mipmap chain
            var width = colorDesc.width;
            var height = colorDesc.height / 2;
            var RTFormat = GraphicsFormat.R16G16B16A16_SFloat;
            mips[0] = (RTHandles.Alloc(width, height, colorFormat: RTFormat), null);
            for (int i = 1; i < MaxMipMapLevel; i++)
            {
                width /= 2;
                if ( width < 4) 
                {
                    mips[i] = (null, null);
                }
                else
                {   
                    colorDesc.width = width;
                    colorDesc.height = height;

                    RenderingUtils.ReAllocateIfNeeded(ref mips[i].down, colorDesc, name: "_RTMipDown" + i);
                    RenderingUtils.ReAllocateIfNeeded(ref mips[i].down, colorDesc, name: "_RTMipDown" + i);
                }
            }
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
                MaterialPropertyBlock s_PropertyBlock = new MaterialPropertyBlock();

                float nearClipZ = -1;
                if (SystemInfo.usesReversedZBuffer)
                    nearClipZ = 1;

                Mesh s_TriangleMesh = new Mesh();
                
                s_TriangleMesh.vertices = GetFullScreenTriangleVertexPosition(nearClipZ);
                s_TriangleMesh.uv = GetFullScreenTriangleTexCoord();
                s_TriangleMesh.triangles = new int[3] { 0, 1, 2 };

                CoreUtils.SetRenderTarget(cmd, m_cameraColorTarget);
                m_material.SetTexture("_CamColTex", m_cameraColorTarget);
                s_PropertyBlock.SetTexture("_CamColTex", m_cameraColorTarget);
                cmd.DrawMesh(s_TriangleMesh, Matrix4x4.identity, m_material, 0, 0, s_PropertyBlock);

                // int level = 1;
                // for (; level < MaxMipMapLevel && mips[level].down != null ; level++)
                // {   
                //     s_PropertyBlock.SetTexture("_InputTex", mips[level - 1].down);
                //     m_material.SetTexture("_InputTex", mips[level - 1].down);
                //     CoreUtils.SetRenderTarget(cmd, mips[level].down);
                //     Blitter.BlitTexture(cmd, mips[level - 1].down, Vector2.one, m_material, 0);
                // }

                // cmd.SetGlobalTexture("_CamColTex", rtTempColor0);
                // CoreUtils.SetRenderTarget(cmd, m_cameraColorTarget);
                // cmd.DrawProcedural(Matrix4x4.identity, m_material, 0, MeshTopology.Triangles, 3, 1, s_PropertyBlock);

                // Prefilter
                // CameraColorTarget -> Prefilter -> MIP 0
                
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            CommandBufferPool.Release(cmd);

        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            base.OnCameraCleanup(cmd);
        }

        public void Dispose()
        {   
            if (rtTempColor0 != null) RTHandles.Release(rtTempColor0);
            if (rtTempColor1 != null) RTHandles.Release(rtTempColor1);

            for (int i = 0; i < MaxMipMapLevel; i++)
            {
                if (mips[i].down != null) RTHandles.Release(mips[i].down);
                if (mips[i].up != null) RTHandles.Release(mips[i].up);
            }
        }

        #region PRIVATE_METHODS

        static Vector3[] GetFullScreenTriangleVertexPosition(float z /*= UNITY_NEAR_CLIP_VALUE*/)
        {
            var r = new Vector3[3];
            for (int i = 0; i < 3; i++)
            {
                Vector2 uv = new Vector2((i << 1) & 2, i & 2);
                r[i] = new Vector3(uv.x * 2.0f - 1.0f, uv.y * 2.0f - 1.0f, z);
            }
            return r;
        }

        static Vector2[] GetFullScreenTriangleTexCoord()
        {
            var r = new Vector2[3];
            for (int i = 0; i < 3; i++)
            {
                if (SystemInfo.graphicsUVStartsAtTop)
                    r[i] = new Vector2((i << 1) & 2, 1.0f - (i & 2));
                else
                    r[i] = new Vector2((i << 1) & 2, i & 2);
            }
            return r;
        }

        #endregion
    }

}