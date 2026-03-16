Shader "DP/BallShaderUnlit"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (0.9, 0.9, 0.8, 1)

        _AspectRatio("Aspect Ratio", float) = 1.0
        
        [Header(Line Settings)]
        [IntRange] _HasLine("Has Line", Range(0, 1)) = 1
        _LineThickness("Line Thickness", Range(0, 0.5)) = 0.174
        _LineColor("Line Color", Color) = (1, 1, 1, 1)

        [Header(Number Circle Settings)]
        _Radius("Circle Radius", float) = 0.16
        
        [Header(Number Settings)]
        _NumbersColor("Numbers Color", Color) = (0, 0, 0, 1)
        _NumbersTexture("Numbers Texture", 2D) = "white" {}
        [IntRange] _Number("Number", Range(0, 15)) = 3

        _A("A", Range(0, 1)) = 0.9
        _B("B", Range(0, 1)) = 0.75
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_NumbersTexture);
            SAMPLER(sampler_NumbersTexture);

            float _AspectRatio;

            float _HasLine;
            float _LineThickness;
            float4 _LineColor;

            float _Radius;

            float4 _NumbersColor;
            float _Number;

            float _A;
            float _B;

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _NumbersTexture_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _NumbersTexture);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = lerp(_LineColor, _BaseColor, _HasLine);
                
                float lineCenter = 0.5;

                float distanceFromCenter = abs(IN.uv.y - lineCenter);
                float lineMask = step(distanceFromCenter, _LineThickness);

                color.rgb = lerp(color.rgb, _LineColor.rgb, lineMask);

                float2 circleUVs = IN.uv;
                circleUVs = frac(circleUVs);

                float2 center = float2(0.5, 0.5);
                center.x *= _AspectRatio;

                float dist = distance(circleUVs, center);
                float circleMask = step(dist, _Radius);

                color.rgb = lerp(color.rgb, _BaseColor.rgb, circleMask);

                float2 numberUV = IN.uv;
                // numberUV.x *= 2;
                numberUV = frac(numberUV);
                numberUV -= center;
                numberUV *= 3;
                numberUV += center;
                numberUV *= 0.25;

                float x = fmod(_Number, 4);
                float y = 3 - floor(_Number / 4);
                float2 numberOffset = float2(x, y);
                numberOffset *= 0.25;
                
                float numberSampler = SAMPLE_TEXTURE2D(_NumbersTexture, sampler_NumbersTexture, numberUV + numberOffset).r;

                numberSampler -= _B;
                numberSampler /= _A - _B;
                numberSampler = saturate(numberSampler);

                float maskedNumber = lerp(0.0, numberSampler, circleMask);
                
                color.rgb = lerp(color.rgb, _NumbersColor.rgb, maskedNumber);

                return color;
            }
            ENDHLSL
        }
    }
}
