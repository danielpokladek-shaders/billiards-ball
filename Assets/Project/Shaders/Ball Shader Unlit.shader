Shader "DP/BallShaderUnlit"
{
    Properties
    {
        [Header(Color Settings)]
        _Base_Color("Base Color", Color) = (0.9, 0.9, 0.8, 1)
        _Accent_Color("Accent Color", Color) = (1, 1, 1, 1)
        _Numbers_Color("Number Color", Color) = (0, 0, 0, 1)
        
        [Header(Line Settings)]
        [IntRange] _Has_Line("Has Line", Range(0, 1)) = 1
        _Line_Thickness("Line Thickness", Range(0, 0.5)) = 0.174

        [Header(Number Circle Settings)]
        _Radius("Circle Radius", float) = 0.16
        
        [Header(Number Settings)]
        _Number_Atlas("Atlas Texture", 2D) = "white" {}
        _Number_Atlas_Size("Atlas Size", Integer) = 4
        [IntRange] _Number("Number", Range(0, 15)) = 3
        _Edge_Min("Edge Min Threshold", Range(0, 1)) = 0.9
        _Edge_Max("Edge Max Threshold", Range(0, 1)) = 0.75
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

            TEXTURE2D(_Number_Atlas);
            SAMPLER(sampler_Number_Atlas);
            float4 _Number_Atlas_ST;

            half4 _Base_Color;

            int _Has_Line;
            half _Line_Thickness;
            half4 _Accent_Color;

            half _Radius;

            int _Number_Atlas_Size;
            half4 _Numbers_Color;
            half _Number;

            half _Edge_Min;
            half _Edge_Max;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _Number_Atlas);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Precalculated shared properties
                half gridInv = (float)1 / _Number_Atlas_Size;
                int vOffset = _Number_Atlas_Size - 1;
                half2 center = float2(0.5, 0.5);

                half4 color = lerp(_Accent_Color, _Base_Color, _Has_Line);
                
                // Horizontal line across ball (stripe)
                float lineDistance = length(IN.uv.y - center.y) - _Line_Thickness;
                float lineMask = smoothstep(0.01, 0.0, lineDistance);
                color.rgb = lerp(color.rgb, _Accent_Color.rgb, lineMask);
                
                // Circle background behind number
                float2 circleUVs = IN.uv;
                circleUVs.x *= 2;
                circleUVs = frac(circleUVs);
                
                float circleDistance = length(circleUVs - center) - _Radius;
                float circleMask = smoothstep(0.01, 0.0, circleDistance) * saturate(_Number);
                color.rgb = lerp(color.rgb, _Base_Color.rgb, circleMask);

                // Calculating UVs for the given number in atlas
                float2 numberUV = IN.uv;
                numberUV.x *= 2;
                numberUV = (frac(numberUV) - center) * vOffset + center;

                float u = fmod(_Number, _Number_Atlas_Size);
                float v = vOffset - floor(_Number * gridInv);
                float2 atlasUV = (numberUV + float2(u, v)) * gridInv;
                
                // Sampling the number from atlas
                float numberSampler = SAMPLE_TEXTURE2D(_Number_Atlas, sampler_Number_Atlas, atlasUV).r;
                numberSampler = 1.0 - numberSampler;
                numberSampler = smoothstep(_Edge_Min, _Edge_Max, numberSampler);

                // Making sure number doesn't spill outside of the circle
                float maskedNumber = lerp(0.0, numberSampler, circleMask);
                color.rgb = lerp(color.rgb, _Numbers_Color.rgb, maskedNumber);

                return color;
            }
            ENDHLSL
        }
    }
}
