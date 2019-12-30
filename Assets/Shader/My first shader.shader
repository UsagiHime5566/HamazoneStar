Shader "Unlit/My first shader"
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
            //#define iTime _Time.y
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

            float PI = 3.1415;
            float unphase = 0.5;
            float rond(float offset,vec2 uv,float r,float phi) {
                uv.x -= offset ;
                
                uv.y -= 0.15 + tan(2.*(_Time.y+2*3*offset))/5.;
                
                float dis = length(uv);
                
                
                float c =  smoothstep(r,r-phi,dis);
                return c ;
            }
            // offset 4.*PI/3.
            float RoundAndFlare(float offset,vec2 uv,float r) {
                float phi_inner = 0.005;
                float phi_outter= 0.001+ clamp(abs(sin(_Time.y))/10.,0.04,0.09) ;
                return 
                rond(0.15*sin(_Time.y+offset),uv,r,phi_inner) + 
                rond(0.15*sin(_Time.y+offset + unphase),uv,r+0.1,phi_outter)/2.;
                
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
                
                float ca = RoundAndFlare(40, uv, 0.3);
                float cb = RoundAndFlare(20, uv, 0.3);
                float cc = RoundAndFlare(0.0         , uv, 0.3);

                vec3 outv=  vec3(ca,cb,cc);
                // float d = (sqrt(ca)+sqrt(cb)+sqrt(cc))/2.;
                float d = 1.;
                
                
                return vec4(outv *d ,1.0);
            }
            ENDCG
        }
    }
}
