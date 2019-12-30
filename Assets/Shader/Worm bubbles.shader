Shader "Unlit/Worm bubbles"
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

            #define _fixed2(x) fixed4(x,x)
            #define _fixed3(x) fixed4(x,x,x)
            #define _fixed4(x) fixed4(x,x,x,x)

            fixed4 frag (v2f i) : SV_Target
            {
                //step1. uv 改為 i.uv , 因為貼圖一定是 1 x 1 矩形, 不必像GLSH一樣局限於瀏覽器長寬
                //step2. iGlobalTime 改為 _Time.y
                //step3. mod 改 fmod  or  #define mod(x,y) (x-y*floor(x/y))
                //step4. mix 改 lerp
                //step5. fract 改 frac
                //step6. in 參數2 fragCoord
                //fragCoord.xy -> gl_FragCoord.xy
                //fragColor -> gl_FragColor
                fixed2 uv = i.uv;   uv = 2.0 * uv - 1.0;

                fixed2 fragCoord = i.uv * 400.0;
                fixed4 fragColor;


                float2 screen = float2(400, 400);
                float t = _Time.y;
                for(int x=0; x<20; x++){
                    for(int y=0; y<20; y++)
                    {
                        fixed4 MySin = 1.0 + sin(t*fixed4(1,3,5,11));
                        float range = length( fragCoord - fixed2(x,y) * screen / 20.0);
                        if(range / screen.y < MySin.w/66.){
                            fragColor = MySin/2.0;
                        }                   
                        t += .1;
                    }
                }

                return fragColor;
            }

            // void mainImage( out vec4 fragColor, vec2 fragCoord ) {
            //     fragCoord = (fragCoord/iResolution.xy) * 400.;
            //     vec2 screen = vec2(400, 400);
            //     float t = iTime;
                
            //     for(int x=0; x<20; x++){
            //         for(int y=0; y<20; y++)
            //         {
            //             vec4 MySin = 1.0 + sin(t*vec4(1,3,5,11));
            //             float range = length( fragCoord - vec2(x,y) * screen / 20.0);
            //             if(range / screen.y < MySin.w/66.){
            //                 fragColor = MySin/2.0;
            //             }                   
            //             t += .1;
            //         }
            //     }
            // }

            ENDCG
        }
    }
}
