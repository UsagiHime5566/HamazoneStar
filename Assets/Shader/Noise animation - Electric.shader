Shader "Unlit/Noise animation - Electric"
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


            // Noise animation - Electric
            // by nimitz (stormoid.com) (twitter: @stormoid)
            // License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
            // Contact the author for other licensing options

            //The domain is displaced by two fbm calls one for each axis.
            //Turbulent fbm (aka ridged) is used for better effect.

            //#define time iTime*0.15
            //#define tau 6.2831853

            mat2 makem2(in float theta){float c = cos(theta);float s = sin(theta);return mat2(c,-s,s,c);}
            float noise( in vec2 x ){return tex2D(iChannel0, x*.01).x;}

            float fbm(in vec2 p)
            {	
                float z=2.;
                float rz = 0.;
                vec2 bp = p;
                for (float i= 1.;i < 6.;i++)
                {
                    rz+= abs((noise(p)-0.5)*2.)/z;
                    z = z*2.;
                    p = p*2.;
                }
                return rz;
            }

            float dualfbm(in vec2 p)
            {
                float time = _Time.y * 0.15;
                //get two rotated fbm calls and displace the domain
                vec2 p2 = p*.7;
                vec2 basis = vec2(fbm(p2-time*1.6),fbm(p2+time*1.7));
                basis = (basis-.5)*.2;
                p += basis;
                
                //coloring
                return fbm(mul(p,makem2(time*0.2)));
            }

            float circ(vec2 p) 
            {
                float r = length(p);
                r = log(sqrt(r));
                return abs(mod(r*4.,6.28)-3.14)*3.+.2;

            }

            fixed4 frag (v2f i) : SV_Target
            {
                //step1. uv 改為 i.uv , 因為貼圖一定是 1 x 1 矩形, 不必像GLSH一樣局限於瀏覽器長寬
                //step2. iGlobalTime 改為 _Time.y
                //step3. mod 改 fmod  or  #define mod(x,y) (x-y*floor(x/y))
                //step4. mix 改 lerp
                //step5. fract 改 frac
                //step6. mat2 矩陣 改為 fixed2x2
                //step7. 矩陣運算 a*b 須改為 mul(a,b)  , 通常發生此問題的編譯錯誤都是 "type mismatch"
                //step8. texture 改 tex2D
                //fragCoord.xy -> gl_FragCoord.xy
                //fragColor -> gl_FragColor
                fixed2 uv = i.uv; uv = 2.0 * uv - 1.0;
                fixed4 fragColor;
                fixed2 fragCoord = i.uv * 400;
                fixed2 iResolution = fixed2(400, 400);

                float time = _Time.y * 0.15;

                //setup system
                vec2 p = fragCoord.xy / iResolution.xy-0.5;
                p.x *= iResolution.x/iResolution.y;
                p*=4.;
                
                float rz = dualfbm(p);
                
                //rings
                p /= exp(mod(time*10.,3.14159));
                rz *= pow(abs((0.1-circ(p))),.9);
                
                //final color
                vec3 col = vec3(.2,0.1,0.4)/rz;
                col=pow(abs(col),svec3(.99));
                fragColor = vec4(col,1.);

                return fragColor;
            }
            ENDCG
        }
    }
}
