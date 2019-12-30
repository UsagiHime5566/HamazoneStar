Shader "Unlit/Rainbow tunnel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        iChannel0("iChannel0", 2D) = "white" {}  
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
            sampler2D iChannel0;
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

            //#define pi  3.14159
            //#define tau 6.28318
            //#define t iTime
            //#define p0 0.5, 0.5, 0.5,  0.5, 0.5, 0.5,  1.0, 1.0, 1.0,  0.0, 0.33, 0.67	
            #define rot(a) fixed2x2(cos(a), -sin(a), sin(a), cos(a)) // col1a col1b col2a col2b

            vec3 palette( in float t, in float a0, in float a1, in float a2, in float b0, in float b1, in float b2, in float c0, in float c1, in float c2,in float d0, in float d1, in float d2)
            {
                return vec3(a0,a1,a2) + vec3(b0,b1,b2)*cos( 6.28318*(vec3(c0,c1,c2)*t+vec3(d0,d1,d2)) );
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
                //fixed2 uv = i.uv; uv = 2.0 * uv - 1.0;
                fixed4 fragColor = svec4(1.);
                fixed2 fragCoord = i.uv * 400;
                fixed2 iResolution = fixed2(400, 400);

                float t = _Time.y ;

                vec2 uv0 = fragCoord.xy / iResolution.xy + vec2(sin(t), cos(t)) * .01;
                vec2 uv = 2. * uv0 - 1.;
                uv.x *= iResolution.x / iResolution.y;
                uv = abs(mul(uv , rot(t * 4.)));
                
                float d = max(uv.x, uv.y);
                
                vec3 color = palette(t, 0.5, 0.5, 0.5,  0.5, 0.5, 0.5,  1.0, 1.0, 1.0,  0.0, 0.33, 0.67);
                
                float uvMax = 1.;
                float innerEdge = mod(t / 1., uvMax);
                float outerEdge = .275 + innerEdge;
                float repeat = .55;
                d = mod(d, repeat) * (uvMax / repeat);
                d += floor(outerEdge/uvMax) * uvMax * step(d, mod(outerEdge, uvMax));
                d = step(innerEdge, d) * step(d, outerEdge);
                
                fragColor.rgb = d * color;

                return fragColor;
            }
            ENDCG
        }
    }
}
