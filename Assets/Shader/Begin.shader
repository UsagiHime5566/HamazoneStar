Shader "Unlit/Begin"
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

            fixed4 frag (v2f i) : SV_Target
            {
                //fixed2 uv = -1.0 + 2.0*fragCoord.xy / iResolution.xy;
                //uv.x *=  iResolution.x / iResolution.y;
                //step1. uv 改為 i.uv , 因為貼圖一定是 1 x 1 矩形, 不必像GLSH一樣局限於瀏覽器長寬
                //step2. iGlobalTime 改為 _Time.y
                //step3. mod 改 fmod  or  #define mod(x,y) (x-y*floor(x/y))
                //step4. mix 改 lerp
                fixed2 uv = i.uv;
                uv = 2.0 * uv - 1.0;

                // background	 
                fixed3 color = fixed3(0.8 + 0.2*uv.y, 0.8 + 0.2*uv.y, 0.8 + 0.2*uv.y);

                // bubbles	
                for( int i=0; i<40; i++ )
                {
                    // bubble seeds
                    float pha =      sin(float(i)*546.13+1.0)*0.5 + 0.5;
                    float siz = pow( sin(float(i)*651.74+5.0)*0.5 + 0.5, 4.0 );
                    float pox =      sin(float(i)*321.55+4.1);

                    // buble size, position and color
                    float rad = 0.1 + 0.5*siz;
                    fixed2  pos = fixed2( pox, -1.0-rad + (2.0+2.0*rad)*fmod(pha+0.1*_Time.y*(0.2+0.8*siz),1.0));
                    float dis = length( uv - pos );
                    fixed3  col = lerp( fixed3(0.94,0.3,0.0), fixed3(0.1,0.4,0.8), 0.5+0.5*sin(float(i)*1.2+1.9));
                    //    col+= 8.0*smoothstep( rad*0.95, rad, dis );
                    
                    // render
                    float f = length(uv-pos)/rad;
                    f = sqrt(clamp(1.0-f*f,0.0,1.0));
                    color -= col.zyx *(1.0-smoothstep( rad*0.95, rad, dis )) * f;
                }

                // vigneting	
                color *= sqrt(1.5-0.5*length(uv));

                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
