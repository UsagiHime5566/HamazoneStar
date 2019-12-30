Shader "Unlit/Fovea detector "
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


            //Human fovea detector by nimitz (twitter: @stormoid)

            /*
            I was playing with procedural texture generation when I came across this.
            You might need to tweak the scale value depending on your monitor's ppi.

            Different shapes might provide better results, haven't tried many.
            */

            //migh need ot tweak this value depending on monitor ppi (tuned for ~100 ppi)
            #define scale 90.

            #define thickness 0.0
            #define lengt 0.13
            #define layers 15.
            #define time _Time.y*3.

            vec2 hash12(float p)
            {
                return fract(vec2(sin(p * 591.32), cos(p * 391.32)));
            }

            float hash21(in vec2 n) 
            { 
                return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
            }

            vec2 hash22(in vec2 p)
            {
                p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
                return fract(sin(p)*43758.5453);
            }

            mat2 makem2(in float theta)
            {
                float c = cos(theta);
                float s = sin(theta);
                return mat2(c,-s,s,c);
            }

            float field1(in vec2 p)
            {
                vec2 n = floor(p)-0.5;
                vec2 f = fract(p)-0.5;
                vec2 o = hash22(n)*.35;
                vec2 r = - f - o;
                r = mul(r , makem2(_Time.y*3.0 + hash21(n) * 3.14));
                
                float d =  1.0-smoothstep(thickness,thickness+0.09,abs(r.x));
                d *= 1.-smoothstep(lengt,lengt+0.02,abs(r.y));
                
                float d2 =  1.0-smoothstep(thickness,thickness+0.09,abs(r.y));
                d2 *= 1.-smoothstep(lengt,lengt+0.02,abs(r.x));
                
                return max(d,d2);
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

                vec2 p = uv;
                
                float myScale = 90;
                float mul = 800/myScale;
                
                vec3 col = svec3(0);
                for (float i=0.;i <layers;i++)
                {
                    vec2 ds = hash12(i*2.5)*.20;
                    col = max(col,field1((p+ds)*mul)*(sin(ds.x*5100. + vec3(1.,2.,3.5))*.4+.6));
                }
                
                return vec4(col,1.0);

            }
            ENDCG
        }
    }
}
