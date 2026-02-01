Shader "Custom/ObraDinnStableDither_V5_HDR_Fix"
{
    Properties
    {
        [HideInInspector] _BlitTexture ("Screen Texture", 2D) = "white" {}
        
        [Header(Texture Setup)]
        _DitherTex ("Dither Pattern", 2D) = "gray" {}
        
        [Header(HDR Control)]
        _InputExposure ("Input Exposure", Range(0.0, 5.0)) = 1.0
        
        [Header(Retro Settings)]
        _PixelSize ("Pixel Scale", Range(1, 6)) = 2
        _DitherScale ("Dither Tiling", Range(100, 1000)) = 400
        
        [Header(Threshold Settings)]
        _Threshold ("Light Threshold", Range(0.0, 1.0)) = 0.5
        _TransitionHardness ("Hardness", Range(1.0, 20.0)) = 5.0
        _DitherStrength ("Dither Visibility", Range(0.0, 1.0)) = 0.5
        
        [Header(Colors)]
        _ColorDark ("Dark Color", Color) = (0.05, 0.22, 0.05, 1) 
        _ColorLight ("Light Color", Color) = (1.0, 0.69, 0.0, 1) 
        
        [Header(Clean Zones)]
        _ShadowClean ("Shadow Clean", Range(0.0, 1.0)) = 0.2
        _HighlightClean ("Highlight Clean", Range(0.0, 1.0)) = 0.8
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        ZTest Always ZWrite Off Cull Off

        Pass
        {
            Name "ObraDinnPassV5"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            struct AttributesDither
            {
                uint vertexID : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VaryingsDither
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };

            SAMPLER(sampler_BlitTexture);
            TEXTURE2D(_DitherTex);
            SAMPLER(sampler_Point_Repeat); 

            float _PixelSize;
            float _DitherScale;
            float _InputExposure;
            float _Threshold;
            float _TransitionHardness; 
            float _DitherStrength;     
            float _ShadowClean;     
            float _HighlightClean;
            float4 _ColorDark;
            float4 _ColorLight;

            float2 PixelateUV(float2 uv, float2 resolution, float scale)
            {
                if (scale <= 1.0) return uv;
                float2 pixelCount = resolution / scale;
                return floor(uv * pixelCount) / pixelCount;
            }

            VaryingsDither Vert (AttributesDither input)
            {
                VaryingsDither output;
                UNITY_SETUP_INSTANCE_ID(input);
                float4 pos = GetFullScreenTriangleVertexPosition(input.vertexID);
                float2 uv  = GetFullScreenTriangleTexCoord(input.vertexID);
                output.positionCS = pos;
                output.uv = uv;
                float4 ndc = float4(uv * 2.0 - 1.0, 1.0, 1.0);
                float3 viewVector = mul(unity_CameraInvProjection, ndc).xyz;
                viewVector = mul(unity_CameraToWorld, float4(viewVector, 0.0)).xyz;
                output.viewDirWS = normalize(viewVector);
                return output;
            }

            float4 Frag (VaryingsDither input) : SV_Target
            {
                float2 retroUV = PixelateUV(input.uv, _ScreenParams.xy, _PixelSize);
                float4 sceneColor = SAMPLE_TEXTURE2D(_BlitTexture, sampler_BlitTexture, retroUV);
                float lum = Luminance(sceneColor.rgb);

                lum *= _InputExposure;
                lum = saturate(lum);

                float offsetLum = lum - _Threshold;
                float squeezedLum = offsetLum * _TransitionHardness + 0.5;
                squeezedLum = saturate(squeezedLum);

                float3 dir = normalize(input.viewDirWS);
                float2 sphereUV;
                sphereUV.x = atan2(dir.z, dir.x) / (2.0 * PI) + 0.5;
                sphereUV.y = asin(dir.y) / PI + 0.5;                 
                
                float ditherValue = SAMPLE_TEXTURE2D(_DitherTex, sampler_Point_Repeat, sphereUV * _DitherScale).r;
                ditherValue = (ditherValue - 0.5) * _DitherStrength + 0.5;

                float binary = step(ditherValue, squeezedLum);

                if (lum < (_Threshold - (1.0 - _ShadowClean)*0.5)) binary = 0.0; 
                else if (lum > (_Threshold + (1.0 - _HighlightClean)*0.5)) binary = 1.0;

                return lerp(_ColorDark, _ColorLight, binary);
            }
            ENDHLSL
        }
    }
}