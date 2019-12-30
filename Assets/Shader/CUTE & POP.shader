Shader "Unlit/CUTE & POP"
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

            float distfunc(vec3 p)
            {
                p=sin(p);
                p-=0.5;
                return length(p)-0.4;
            }

            float rand(vec2 co){
                return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
            }

            fixed4 frag (v2f input) : SV_Target
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
                fixed2 uv = input.uv; uv = 2.0 * uv - 1.0;
                fixed4 fragColor;
                fixed2 fragCoord = input.uv * 400;
                fixed2 iResolution = fixed2(400, 400);

                float time=iTime;
                vec2 p=(2.0*fragCoord.xy-iResolution.xy)/min(iResolution.x,iResolution.y)*0.5;

                float z0=time*28.0/1.0;
                float i=floor(z0);
                float offs=fract(z0);
                float shadow=1.0;

                for(float z=1.0;z<150.0;z+=1.0)
                {
                    float z2=z-offs;
                    float randz=z+i;
                    float dadt=(rand(vec2(randz,1.0))*2.0-1.0)*0.5;
                    float a=rand(vec2(randz,1.0))*2.0*3.141592+dadt*time;
                    float pullback=rand(vec2(randz,3.0))*4.0+1.0;
                    float r=rand(vec2(randz,4.0))*0.5+1.4;
                    float g=rand(vec2(randz,5.0))*0.5+0.7;
                    float b=rand(vec2(randz,6.0))*0.5+0.7;

                    vec2 origin=vec2(sin(randz*0.005)+sin(randz*0.002),cos(randz*0.005)+cos(randz*0.002))*z2*0.002;
                    
                    vec2 dir=vec2(cos(a),sin(a));
                    float dist=dot(dir,p-origin)*z2;
                    float xdist=dot(vec2(-dir.y,dir.x),p-origin)*z2;
                    float wobble=dist-pullback+sin(xdist*20.0)*0.05;
                    if(wobble>0.0)
                    {
                        float dotsize=rand(vec2(randz,7.0))*0.5+0.1;
                        float patternsize=rand(vec2(randz,8.0))*2.0+2.0;
                        float pattern=step(dotsize,length(fract(vec2(dist,xdist)*patternsize)-0.5))*0.1+0.9;

                        float bright;
                        if(wobble<0.2) bright=1.2;
                        else if(wobble<0.22) bright=0.9;
                        else bright=1.0*pattern;

                        fragColor=vec4(30.0*vec3(r,g,b)*shadow/(z2+30.0)*bright,1.0);
                        return fragColor;
                    }
                    else
                    {
                        shadow*=1.0-exp((dist-pullback)*2.0)*0.2;
                    }
                }
                fragColor=vec4(svec3(0.0),1.0);

                return fragColor;
            }
            ENDCG
        }
    }
}
