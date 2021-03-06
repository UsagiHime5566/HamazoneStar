﻿Shader "Unlit/Rainbow Ring Illusion"
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
            #define texture2D tex2D

            #define _fixed2(x) fixed2(x,x)
            #define _fixed3(x) fixed3(x,x,x)
            #define _fixed4(x) fixed4(x,x,x,x)

            bool ring(vec2 origin,float radius,float width){//Function for drawing ring
                if(length(origin) < radius && length(origin) > radius - width){//Test if current pixel is within ring surface
                    return(true);//Return true if the point is within the ring
                }
                return(false);//Return false otherwise
            }
            bool circle(vec2 origin,float radius){//Function for drawing ring
                if(length(origin) < radius){//Test if current pixel is within ring surface
                    return(true);//Return true if the point is within the ring
                }
                return(false);//Return false otherwise
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
                fixed4 fragColor;
                fixed2 fragCoord = i.uv * 400;
                fixed2 iResolution = fixed2(400, 400);


                vec4 finalcol;//Variable to hold the final color for this pixel
                vec2 mpoint = (fragCoord.xy - iResolution.xy/2.0);

                float pi = 3.14159265;
                
                float sec = iTime*2.0*pi;//time multiplied by 2pi. Using this as sin or cos input makes the function's period 1 second
                float dens = 100.0;//Density of colors, higher values increases the distance between color changes
                float doff = -.5*sec;//Speed at which the colors scroll across the rings
                
                for(float i = 10.0; i < 600.0/*Controls maximum radius*/; i+=10.0/*Controls difference in radius between rings*/){//For loop that creates the many different rings: i value is radius. 
                    if(ring(vec2(mpoint.x + i*.5*cos(sec*.15),mpoint.y + i*.5*sin(sec*.15)),i,2.0+ i*.01) || circle(mpoint,1.0)){//Evaluate rings and offset them using trig functions.
                        finalcol=vec4(sin(i*pi/dens + doff),cos(i*pi/dens + doff),cos(i*pi/dens + pi/1.3 + doff),1.0);//Apply the colors and change each colors balance using trig functions
                        break;
                    }
                    else {
                        finalcol = vec4(0.0,0.0,0.0,1.0);
                    }//If not in a ring set color to black
                }
                fragColor = finalcol;
                return fragColor;
            }
            ENDCG
        }
    }
}
