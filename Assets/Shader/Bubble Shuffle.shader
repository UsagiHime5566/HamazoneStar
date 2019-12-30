Shader "Unlit/Bubble Shuffle"
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

            float random(vec2 st) {
                return fract(sin(dot(st, vec2(12.9898,78.233))) * 43758.5453123);
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
                fixed2 uv = i.uv; uv = 2.0 * uv - 1.0;

                //vec2 uv = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y; 
                vec2 scaleUv = uv * 25.0;
                
                float s = 2.0 * sin(iTime * 1.5);   
                float slideX = s * (floor(s * 0.5) + 1.0) * mix(-1.0, 1.0, mod(floor(scaleUv.y), 2.0));
                float slideY = s * -floor(s * 0.5) * mix(-1.0, 1.0, mod(floor(scaleUv.x), 2.0));
                scaleUv += vec2(slideX, slideY);
                
                vec2 flUv = floor(scaleUv);
                vec2 frUv = fract(scaleUv);
                
                float t = 5.0 * iTime + random(flUv) * 100.0;
                
                float center = 0.55 * length(uv) + 0.45;
                float sizeAnim = (1.0 - (sin(t) * 0.15 + 0.65)) * center;
                float mask = smoothstep(sizeAnim, sizeAnim - 0.05, distance(frUv, svec2(0.5)));
                
                float r = random(flUv);
                float g = random(flUv + 1.0);
                float b = random(flUv - 1.0);
                vec3 col = mask * vec3(r, g, b);
                return vec4(col, 1.0);
            }
            ENDCG
        }
    }
}
