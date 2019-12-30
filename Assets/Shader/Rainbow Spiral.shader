Shader "Unlit/Rainbow Spiral"
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

            
            #define PI 3.14159265359
            #define E 2.7182818284
            #define GR 1.61803398875
            #define EPS .001

            #define time (float(__LINE__)+iTime/PI)

            float saw(float x)
            {
                return acos(cos(x))/3.14;
            }
            vec2 saw(vec2 x)
            {
                return acos(cos(x))/3.14;
            }
            vec3 saw(vec3 x)
            {
                return acos(cos(x))/3.14;
            }
            vec4 saw(vec4 x)
            {
                return acos(cos(x))/3.14;
            }
            float stair(float x)
            {
                return float(int(x));
            }
            vec2 stair(vec2 x)
            {
                return vec2(stair(x.x), stair(x.y));
            }


            float jag(float x)
            {
                return mod(x, 1.0);
            }
            vec2 jag(vec2 x)
            {
                return vec2(jag(x.x), jag(x.y));
            }



            vec2 SinCos( const in float x )
            {
                return vec2(sin(x), cos(x));
            }
            vec3 RotateZ( const in vec3 vPos, const in vec2 vSinCos )
            {
                return vec3( vSinCos.y * vPos.x + vSinCos.x * vPos.y, -vSinCos.x * vPos.x + vSinCos.y * vPos.y, vPos.z);
            }
            
            vec3 RotateZ( const in vec3 vPos, const in float fAngle )
            {
                return RotateZ( vPos, SinCos(fAngle) );
            }
            vec2 RotateZ( const in vec2 vPos, const in float fAngle )
            {
                return RotateZ( vec3(vPos, 0.0), SinCos(fAngle) ).xy;
            }
            mat4 RotateZ( const in mat4 vPos, const in float fAngle )
            {
                return mat4(RotateZ( vec3(vPos[0].xy, 0.0), SinCos(fAngle) ).xy, 0.0, 0.0,
                RotateZ( vec3(vPos[1].xy, 0.0), SinCos(fAngle) ).xy, 0.0, 0.0,
                RotateZ( vec3(vPos[2].xy, 0.0), SinCos(fAngle) ).xy, 0.0, 0.0,
                RotateZ( vec3(vPos[3].xy, 0.0), SinCos(fAngle) ).xy, 0.0, 0.0);
            }
            mat4 translate( const in mat4 vPos, vec2 offset )
            {
                return mat4(vPos[0].xy+offset, 0.0, 0.0,
                vPos[1].xy+offset, 0.0, 0.0,
                vPos[2].xy+offset, 0.0, 0.0,
                vPos[3].xy+offset, 0.0, 0.0);
            } 
            mat4 scale( const in mat4 vPos, vec2 factor )
            {
                return mat4(vPos[0].xy*factor, 0.0, 0.0,
                vPos[1].xy*factor, 0.0, 0.0,
                vPos[2].xy*factor, 0.0, 0.0,
                vPos[3].xy*factor, 0.0, 0.0);
            } 
            vec4 spiral(vec4 uv)
            {
                //uv = normalize(uv)*log(length(uv)+1.0);
                float r = log(length(uv)+1.0)*2.0*PI;
                float theta = mod((atan(uv.y, uv.x)+r), 2.0*PI);
                
                return vec4(saw(r), saw(theta),
                r, theta);
            }


            float square(vec2 uv, float iteration)
            {
                if(abs(abs(saw(uv.x*(1.5+sin(iTime*.654321))*PI+iTime*.7654321)*2.0-1.0)-abs(uv.y)) < .5)
                return 1.0-abs(abs(saw(uv.x*(1.5+sin(iTime*.654321))*PI+iTime*.7654321)*2.0-1.0)-abs(uv.y))/.5*uv.x;
                else
                return 0.0;
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
                //fixed4 uv = i.uv; uv = 2.0 * uv - 1.0;
                fixed4 fragColor;
                fixed2 fragCoord = i.uv * 400;
                fixed2 iResolution = fixed2(400, 400);

                vec4 uv = vec4(i.uv, 0.0, 0.0);
                
                float map = 0.0;
                
                float lambda = 4.0;
                float amplitude = 32.0;
                float scale = pow(E, saw(time)*amplitude);
                uv.xy *= scale;
                uv.xy -= scale/2.0;
                uv.x *= iResolution.x/iResolution.y;
                uv.xy = normalize(uv.xy)*log(length(uv.xy)+1.0);
                
                const int max_iterations = 1;

                float noise = 1.0;
                
                for(int i = 0; i < max_iterations; i++)
                {
                    uv = spiral(uv);
                    uv.xy *= scale;
                    uv.xy -= scale/2.0;
                    uv.xy = normalize(uv.xy)*log(length(uv.xy)+1.0);
                    map += (uv.z+uv.w);
                }
                
                fragColor.rg = saw(uv.zw);//saw(uv.zw*PI);
                fragColor.b = 0.0;
                fragColor.a = 1.0;
                
                
                fragColor = vec4(vec3(saw(map),
                saw(4.0*PI/3.0+map),
                saw(2.0*PI/3.0+map)),
                1.0);

                return fragColor;
            }
            ENDCG
        }
    }
}
