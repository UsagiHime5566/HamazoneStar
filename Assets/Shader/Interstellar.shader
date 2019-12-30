Shader "Unlit/Interstellar"
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

            const float tau = 6.28318530717958647692;

            // Gamma correction
            #define GAMMA (2.2)

            vec3 ToLinear( in vec3 col )
            {
                // simulate a monitor, converting colour values into light values
                return pow( col, svec3(GAMMA) );
            }

            vec3 ToGamma( in vec3 col )
            {
                // convert back into colour values, so the correct light will come out of the monitor
                return pow( col, svec3(1.0/GAMMA) );
            }

            vec4 Noise( in ivec2 x )
            {
                float2 y = (float2)x;
                return tex2D( iChannel0, (y + 0.5)/256.0 );
            }

            vec4 Rand( in int x )
            {
                vec2 uv;
                uv.x = (float(x)+0.5)/256.0;
                uv.y = (floor(uv.x)+0.5)/256.0;
                return tex2D( iChannel0, uv);
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
                //int2 轉換為 float2  ->  (float2)int2
                //fragCoord.xy -> gl_FragCoord.xy
                //fragColor -> gl_FragColor
                fixed2 uv = i.uv; uv = 2.0 * uv - 1.0;
                fixed4 fragColor;
                fixed2 fragCoord = i.uv * 400;
                fixed2 iResolution = fixed2(400, 400);

                vec3 ray;
                ray.xy = 2.0*(fragCoord.xy-iResolution.xy*.5)/iResolution.x;
                ray.z = 1.0;

                float offset = iTime*.5;	
                float speed2 = (cos(offset)+1.0)*2.0;
                float speed = speed2+.1;
                offset += sin(offset)*.96;
                offset *= 2.0;
                
                
                vec3 col = svec3(0);
                
                vec3 stp = ray/max(abs(ray.x),abs(ray.y));
                
                vec3 pos = 2.0*stp+.5;
                for ( int i=0; i < 20; i++ )
                {
                    float z = Noise(ivec2(pos.xy)).x;
                    z = fract(z-offset);
                    float d = 50.0*z-pos.z;
                    float w = pow(max(0.0,1.0-8.0*length(fract(pos.xy)-.5)),2.0);
                    vec3 c = max(svec3(0),vec3(1.0-abs(d+speed2*.5)/speed,1.0-abs(d)/speed,1.0-abs(d-speed2*.5)/speed));
                    col += 1.5*(1.0-z)*c*w;
                    pos += stp;
                }
                
                fragColor = vec4(ToGamma(col),1.0);

                return fragColor;
            }
            ENDCG
        }
    }
}
