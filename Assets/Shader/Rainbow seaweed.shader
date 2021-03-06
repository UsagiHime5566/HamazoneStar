﻿Shader "Unlit/Rainbow seaweed"
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
            #define ivec2 int2
            #define ivec3 int3
            #define ivec4 int4
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
            #define atan atan2
            #define texture2D tex2D

            #define _fixed2(x) fixed2(x,x)
            #define _fixed3(x) fixed3(x,x,x)
            #define _fixed4(x) fixed4(x,x,x,x)

            float noise11(in float x) {
                return fract(sin(x)*35746.1764); 
            }
            
            vec3 rgb(in float hue)
            {
                // Hue [0..1] to RGB [0..1]
                // See http://www.chilliant.com/rgb2hsv.html
                vec3 rgb = abs(hue * 6. - vec3(3, 2, 4)) * vec3(1, -1, -1) + vec3(-1, 2, 2);
                return clamp(rgb, 0., 1.);
            }

            vec3 pointf(in vec2 uv) {
                float id = floor(uv.x);
                uv = fract(uv) + svec2(0.5);
                vec2 pos = uv + vec2(sin(uv.y * 6. + noise11(id) * 2004.) * 0.8 - 1., cos(iTime * 2.));
                return rgb(id / 21.5) / length((pos) * vec2(1., 0.05)) * 0.1; 
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
                fixed4 fragColor;
                fixed2 fragCoord = i.uv * 400;
                fixed2 iResolution = fixed2(400, 400);

                uv = fixed2(uv.y, uv.x);
                uv *= vec2(iResolution.x / iResolution.y * 9., 0.5);
                fragColor = vec4(pointf(vec2(uv.x, uv.y * cos(iTime*2.) + 0.5)), 1.0);

                return fragColor;
            }
            ENDCG
        }
    }
}
