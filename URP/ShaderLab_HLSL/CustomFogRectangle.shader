Shader "BalanceBoard/CustomFogRectangle"
{
    Properties
    {
        [Header(Main parameters)]
        [NoScaleOffset] _BaseMap ("BaseMap", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        [Header(Rectangle bounds)][Space(10)]
         _BoundsWidth ("BoundsWidth", Range (0.1, 16)) = 8
        _BoundsHeight ("BoundsHeight", Range (0.1, 9)) = 4.8
        [Header(Keywords)]
        [Toggle(_CUSTOM_LIGHT_ON)] _CustomLight ("CustomLight", Float) = 0
        // _GlobalOcclusion ("GlobalOcclusion", 2D) = "white" {} //This is global parameter that set's from code with Shader.SetGlobalTexture()
        //[HideInInspector]_LightPosition ("LightPosition", vector) = (0,0,0,0) //This is global parameter that set's from code with Shader.SetGlobalVector()
        //[HideInInspector]_LightRadius ("LightRadius", float) = 4 //This is global parameter that set's from code with Shader.SetGlobalFloat()
    }

    SubShader
    {
        Tags {"RenderPipeline" = "UniversalRenderPipeline" "UniversalMaterialType" = "Unlit" "RenderType"="Transparent" "Queue"="Transparent"}

        Pass
        {
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest LEqual
            ZWrite Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fragment _CUSTOM_LIGHT_OFF _CUSTOM_LIGHT_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv0 : TEXCOORD0;
                half4 color : COLOR;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 texCoord0 : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                half4 color : COLOR;
            };
            
            
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _BoundsWidth;
            half _BoundsHeight;
            CBUFFER_END

            // Object and Global properties
            float3 _LightPosition;
            half _LightRadius;
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_GlobalOcclusion);
            SAMPLER(sampler_GlobalOcclusion);

            // Vertex shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;
                OUT.texCoord0 = IN.uv0;
                OUT.positionWS = positionInputs.positionWS;
                OUT.color = IN.color;
                return OUT;

            }

            // Fragment shader
            half4 frag(Varyings IN) : SV_Target
            {
                // we hardcode the rectangle center to be in world (0,0,0) so we can use abs(coordinate), but if custom center position needed
                // just use distance (IN.positionWS.x, center.x) and the same for y/z
                half width = step(_BoundsWidth, abs(IN.positionWS.x));
                half height = step(_BoundsHeight, abs(IN.positionWS.z));
                half rectangleAlpha = (1 - width) * (1 - height);

                half4 vertexBase = IN.color * _BaseColor; // vertex color multiplied by base color
                half4 finalColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.texCoord0) * vertexBase;

                // Global Occlustion Start
                float2 worldSpaceUVs = IN.positionWS.rb * 0.0624 + float2(0.499, 0.363); // Magic Tiling and Offset for Global Occlusion
                float globalOcclusionMask = smoothstep(0.3, 0.8, SAMPLE_TEXTURE2D(_GlobalOcclusion, sampler_GlobalOcclusion, worldSpaceUVs).r); // Magical smoothstep
                // Global Occlusion end

#ifdef _CUSTOM_LIGHT_ON
                half lightPosToFragDistance = distance(_LightPosition, IN.positionWS);
                half lightConeMask = smoothstep(0, _LightRadius, lightPosToFragDistance);
                lightConeMask = 1 - lightConeMask;
                finalColor.a *= lightConeMask;
#endif
                finalColor.a *= globalOcclusionMask * rectangleAlpha;
                return finalColor;
            }

            ENDHLSL
        }
    }
    FallBack "Lit"
}
