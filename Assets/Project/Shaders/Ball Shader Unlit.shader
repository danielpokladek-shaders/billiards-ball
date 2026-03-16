Shader "DP/BallShaderUnlit"
{
    Properties
    {
        [Header(Base Settings)]
        _BaseColor("Base Color", Color) = (0.9, 0.9, 0.8, 1)
        
        [Header(Line Settings)]
        [IntRange] _HasLine("Has Line", Range(0, 1)) = 1
        _LineThickness("Line Thickness", Range(0, 0.5)) = 0.174
        _LineColor("Line Color", Color) = (1, 1, 1, 1)

        [Header(Number Circle Settings)]
        _Radius("Circle Radius", float) = 0.16
        
        [Header(Number Settings)]
        _NumberAtlas("Atlas Texture", 2D) = "white" {}
        _NumberAtlasSize("Atlas Size", Integer) = 4
        [IntRange] _Number("Number", Range(0, 15)) = 3
        _NumbersColor("Number Color", Color) = (0, 0, 0, 1)
        _EdgeMin("Edge Min Threshold", Range(0, 1)) = 0.9
        _EdgeMax("Edge Max Threshold", Range(0, 1)) = 0.75
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

            TEXTURE2D(_NumberAtlas);
            SAMPLER(sampler_NumberAtlas);
            float4 _NumberAtlas_ST;

            half4 _BaseColor;

            int _HasLine;
            half _LineThickness;
            half4 _LineColor;

            half _Radius;

            int _NumberAtlasSize;
            half4 _NumbersColor;
            half _Number;

            half _EdgeMin;
            half _EdgeMax;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _NumberAtlas);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Precalculated shared properties
                half gridInv = (float)1 / _NumberAtlasSize;
                int uvYOffset = _NumberAtlasSize - 1;
                half2 center = float2(0.5, 0.5);

                half4 color = lerp(_LineColor, _BaseColor, _HasLine);
                
                // Horizontal line across ball (stripe)
                float distanceFromCenter = abs(IN.uv.y - center.x);
                float lineMask = step(distanceFromCenter, _LineThickness);
                color.rgb = lerp(color.rgb, _LineColor.rgb, lineMask);
                
                // Circle background behind number
                float2 circleUVs = IN.uv;
                circleUVs = frac(circleUVs);
                
                float dist = distance(circleUVs, center);
                float circleMask = step(dist, _Radius) * saturate(_Number);
                color.rgb = lerp(color.rgb, _BaseColor.rgb, circleMask);
                
                // Calculating UVs for the given number in atlas
                float2 numberUV = (frac(IN.uv) - center) * uvYOffset + center;
                float x = fmod(_Number, _NumberAtlasSize);
                float y = uvYOffset - floor(_Number * gridInv);
                float2 atlasUV = (numberUV + float2(x, y)) * gridInv;
                
                // Sampling the number from atlas
                float numberSampler = SAMPLE_TEXTURE2D(_NumberAtlas, sampler_NumberAtlas, atlasUV).r;

                // SDF Font - thank you, Ben Cloward.
                numberSampler -= _EdgeMax;
                numberSampler /= _EdgeMin - _EdgeMax;
                numberSampler = saturate(numberSampler);

                // Making sure number doesn't spill outside of the circle
                float maskedNumber = lerp(0.0, numberSampler, circleMask);
                color.rgb = lerp(color.rgb, _NumbersColor.rgb, maskedNumber);

                return color;
            }
            ENDHLSL
        }
    }
}
