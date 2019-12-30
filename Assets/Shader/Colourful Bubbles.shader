Shader "Unlit/Colourful Bubbles"
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

            //Noice function [0,1]
            fixed2 T = fixed2(0, 1);

            float No(float x){
                return frac(9667.5*sin(7983.75*(x + T.x) + 297. + T.y));
            }

            fixed4 Rancol(fixed2 x){
                return fixed4(No(x.x + x.y), No(x.x*x.x+ x.y), No(x.x*x.x + x.y*x.y),1.);
            }

            //bubbles!!
            fixed4 grid(fixed2 uv, float t){
                fixed4 C1, C2;
                uv *= 20.;
                fixed2 id = fixed2(int(uv.x),int(uv.y));
                uv.y += (5.*No(id.x*id.x) + 1.)*t*.4	;
                uv.y += No(id.x);
                id = fixed2(int(uv.x), int(uv.y));
                uv = frac(uv) - .5;

                //if (id == fixed2(1,10)){C1 = fixed4(1.);}

                float d = length(uv);
                t *= 10.*No(id.x + id.y);
                //uv.x += No(id.x);
                //if (uv.x > .46 || uv.y > .46){C1 = fixed4(1.);}

                float r = .1*sin(t + sin(t)*.5)+.3;
                float r1 = .07*sin(2.0*t + sin(2.*t)*0.5) +.1*No(id.x + id.y);
                if (d<r && d>r-.1){
                    C2 = 0.5*Rancol(id + fixed2(1, 1)) + fixed4(0.5, 0.5, 0.5, 0.5);
                    C2 *= smoothstep(r-0.12,r,d);
                    C2 *= 1.0 - smoothstep(r-0.05, r+0.12,d);
                }

                if (d<r1){
                    C2 = .5*Rancol(id + fixed2(1, 1)) + fixed4(0.5, 0.5, 0.5, 0.5);
                }

                return C2;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //step1. uv 改為 i.uv , 因為貼圖一定是 1 x 1 矩形, 不必像GLSH一樣局限於瀏覽器長寬
                //step2. iGlobalTime 改為 _Time.y
                //step3. mod 改 fmod  or  #define mod(x,y) (x-y*floor(x/y))
                //step4. mix 改 lerp
                //step5. fract 改 frac
                fixed2 uv = i.uv;
                uv = 2.0 * uv - 1.0;

                float t = _Time.y;
                return fixed4(grid(uv, t));
            }
            
            ENDCG
        }
    }
}
