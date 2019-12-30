Shader "Unlit/Rainbow Showoff"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            #define vec2 float2
            #define vec3 float3
            #define vec4 float4
            #define svec2(x) float2(x,x)
            #define svec3(x) float3(x,x,x)
            #define svec4(x) float4(x,x,x,x)

            #define mat2 float2x2
            #define mat3 float3x3
            #define mat4 float4x4
            #define iTime _Time.y
            // fmod用于求余数，比如fmod(1.5, 1.0) 返回0.5；
            #define mod fmod
            // 插值运算，lerp(a,b,w) return a + w*(a-b);
            #define mix lerp
            // fract(x): 取小数部分 
            #define fract frac
            #define texture2D tex2D

            #define _fixed2(x) fixed2(x,x)
            #define _fixed3(x) fixed3(x,x,x)
            #define _fixed4(x) fixed4(x,x,x,x)

            #define FALLING_SPEED  0.25
            #define STRIPES_FACTOR 5.0

            //get sphere
            float sphere(vec2 coord, vec2 pos, float r) {
                vec2 d = pos - coord; 
                return smoothstep(60.0, 0.0, dot(d, d) - r * r);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //step1. uv 改為 i.uv , 因為貼圖一定是 1 x 1 矩形, 不必像GLSH一樣局限於瀏覽器長寬
                //step2. iGlobalTime 改為 _Time.y
                //step3. mod 改 fmod  or  #define mod(x,y) (x-y*floor(x/y))
                //step4. mix 改 lerp
                //step5. fract 改 frac
                //step6. mat2 矩陣 改為 fixed2x2
                //step7. 矩陣運算 a*b 須改為 mul(a,b)
                //fragCoord.xy -> gl_FragCoord.xy
                //fragColor -> gl_FragColor
                fixed2 uv = i.uv; //uv = 2.0 * uv - 1.0;
                fixed4 fragColor;
                fixed2 fragCoord = uv * 400;
                fixed2 iResolution = fixed2(400, 400);

                //normalize pixel coordinates

                //pixellize uv
                vec2 clamped_uv = (round(fragCoord / STRIPES_FACTOR) * STRIPES_FACTOR) / iResolution.xy;
                //get pseudo-random value for stripe height
                float value		= fract(sin(clamped_uv.x) * 43758.5453123);
                //create stripes
                vec3 col        = svec3(1.0 - mod(uv.y * 0.5 + (iTime * (FALLING_SPEED + value / 5.0)) + value, 0.5));
                //add color
                col       *= clamp(cos(iTime * 2.0 + uv.xyx + vec3(0, 2, 4)), 0.0, 1.0);
                //add glowing ends
                col 	   += svec3(sphere(fragCoord, 
                vec2(clamped_uv.x, (1.0 - 2.0 * mod((iTime * (FALLING_SPEED + value / 5.0)) + value, 0.5))) * iResolution.xy, 
                0.9)) / 2.0; 
                //add screen fade
                col       *= svec3(exp(-pow(abs(uv.y - 0.5), 6.0) / pow(2.0 * 0.05, 2.0)));
                // Output to screen
                fragColor       = vec4(col,1.0);

                return fragColor;
            }
            ENDCG
        }
    }
}
