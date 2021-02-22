Shader "SKATRIX/ScanningPlane"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.784, 0.784, 0.784, 1)
        [NoScaleOffset] _BaseMask ("Base Mask", 2D) = "white" {}
        [NoScaleOffset] _NoiseGradientMask ("Noise Gradient Mask", 2D) = "white" {}
        _TilesStretch ("Tiles Stretch", Range (0.1, 0.3)) = 0.2
        _Tiling ("Tiling", Range (1, 3)) = 2
        _Transparency ("Transparency", Range (0, 0.3)) = 0.01
    }
    SubShader
    {
        Tags 
        {
        "RenderPipeline" = "UniversalRenderPipeline"
        "UniversalMaterialType" = "Unlit"
        "RenderType"="Opaque"
        "Queue"="Geometry"
        "IgnoreProjector" = "True"
        }

        Pass
        {
            Cull Back
            Blend SrcAlpha One
            ZTest LEqual
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag            
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionOS : TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _TilesStretch;
            half _Tiling;
            half _Transparency;
            CBUFFER_END

            // Object and Global properties
            TEXTURE2D(_BaseMask);
            SAMPLER(sampler_BaseMask);

            TEXTURE2D(_NoiseGradientMask);
            SAMPLER(sampler_NoiseGradientMask);

            // Vertex shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionOS = IN.positionOS.xyz;
                return OUT;
            }

            // Fragment shader
            half4 frag(Varyings IN) : SV_Target
            {
                half4 finalColor = _BaseColor;

                // Gradient Noise
                float2 timeOffset;
                timeOffset.r = 0;
                timeOffset.g = _Time;
                float2 noiseMaskUV = IN.positionOS.rb * 0.05 + timeOffset; // 0.05 is hardcoded tiling for that noise mask
                half noiseMask = SAMPLE_TEXTURE2D(_NoiseGradientMask, sampler_NoiseGradientMask, noiseMaskUV);
                noiseMask = clamp(noiseMask, 0.2, 1); // Magin clamp of the noise mask

                // Tiling and sampling of hexagon mask
                float2 tiling = _Tiling;
                tiling.r += _TilesStretch;
                float2 objectSpaceUVs = IN.positionOS.rb * tiling;
                half finalAlpha = 1 - SAMPLE_TEXTURE2D(_BaseMask, sampler_BaseMask, objectSpaceUVs).r;
                finalAlpha *= noiseMask; // Account for Noise Mask

                finalColor.a = clamp(finalAlpha, _Transparency, 1);
                return finalColor;
            }

            ENDHLSL
        }
    }
    FallBack "Lit"
}
