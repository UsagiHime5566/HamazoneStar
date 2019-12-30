Shader "Unlit/Bubble dist plasma"
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

            #define _fixed2(x) fixed2(x,x)
            #define _fixed3(x) fixed3(x,x,x)
            #define _fixed4(x) fixed4(x,x,x,x)

            #define NOISE 2 // Perlin, Worley1, Worley2

            #define PI 3.14159

            // --- noise functions from https://www.shadertoy.com/view/XslGRr
            // Created by inigo quilez - iq/2013
            // License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

            const fixed3x3 m = fixed3x3( 0.00,  0.80,  0.60,
            -0.80,  0.36, -0.48,
            -0.60, -0.48,  0.64 );

            float hash( float n ) {
                return frac(sin(n)*43758.5453);
            }

            float noise( in fixed3 x ) { // in [0,1]
                fixed3 p = floor(x);
                fixed3 f = frac(x);

                f = f*f*(3.-2.*f);

                float n = p.x + p.y*57. + 113.*p.z;

                float res = lerp(lerp(lerp( hash(n+  0.), hash(n+  1.),f.x),
                lerp( hash(n+ 57.), hash(n+ 58.),f.x),f.y),
                lerp(lerp( hash(n+113.), hash(n+114.),f.x),
                lerp( hash(n+170.), hash(n+171.),f.x),f.y),f.z);
                return res;
            }

            float fbm( fixed3 p ) { // in [0,1]
                float f;
                f  = 0.5000*noise( p ); p = mul(p,m)*2.02;
                f += 0.2500*noise( p ); p = mul(p,m)*2.03;
                f += 0.1250*noise( p ); p = mul(p,m)*2.01;
                f += 0.0625*noise( p );
                return f;
            }
            // --- End of: Created by inigo quilez --------------------

            // more 2D noise
            fixed2 hash12( float n ) {
                return frac(sin(n+fixed2(1.,12.345))*43758.5453);
            }
            float hash21( fixed2 n ) {
                return hash(n.x+10.*n.y);
            }
            fixed2 hash22( fixed2 n ) {
                return hash12(n.x+10.*n.y);
            }
            float cell;   // id of closest cell
            fixed2  center; // center of closest cell

            fixed3 worley( fixed2 p ) {
                fixed3 d = _fixed3(1e15);
                fixed2 ip = floor(p);
                for (float i=-2.; i<3.; i++)
                for (float j=-2.; j<3.; j++) {
                    fixed2 p0 = ip+fixed2(i,j);
                    float a0 = hash21(p0), a=5.*a0*_Time.y+2.*PI*a0; fixed2 dp=fixed2(cos(a),sin(a)); 
                    fixed2  c = hash22(p0)*.5+.5*dp+p0-p;
                    float d0 = dot(c,c);
                    if      (d0<d.x) { d.yz=d.xy; d.x=d0; cell=hash21(p0); center=c;}
                    else if (d0<d.y) { d.z =d.y ; d.y=d0; }
                    else if (d0<d.z) {            d.z=d0; }  
                }
                return sqrt(d);
            }

            // distance to Voronoi borders, as explained in https://www.shadertoy.com/view/ldl3W8 
            float worleyD( fixed2 p) {
                float d = 1e15;
                fixed2 ip = floor(p);
                for (float i=-2.; i<3.; i++)
                for (float j=-2.; j<3.; j++) {
                    fixed2 p0 = ip+fixed2(i,j);
                    float a0 = hash21(p0), a=5.*a0*_Time.y+2.*PI*a0; fixed2 dp=fixed2(cos(a),sin(a)); 
                    fixed2  c = hash22(p0)*.5+.5*dp+p0-p;
                    float d0 = dot(c,c);
                    float c0 = dot(center+c,normalize(c-center));
                    d=min(d, c0);
                }

                return .5*d;
            }


            float grad, scale = 5.; 

            // my noise
            float tweaknoise( fixed2 p) {
                float d=0.;
                for (float i=0.; i<5.; i++) {
                    float a0 = hash(i+5.6789), a=1.*a0*_Time.y+2.*PI*a0; fixed2 dp=fixed2(cos(a),sin(a)); 
                    
                    fixed2 ip = hash12(i+5.6789)+dp;
                    float di = smoothstep(grad/2.,-grad/2.,length(p-ip)-.5);
                    d += (1.-d)*di;
                }
                //float d = smoothstep(grad/2.,-grad/2.,length(p)-.5);
                #if NOISE==1 // 3D Perlin noise
                    float v = fbm(fixed3(scale*p,.5));
                #elif NOISE==2 // Worley noise
                    float v = 1. - scale*worley(scale*p).x;
                #elif NOISE>=3 // trabeculum 2D
                    if (d<0.5) return 0.;
                    grad=.8, scale = 5.;
                    fixed3 w = scale*worley(scale*p);
                    float v;
                    if (false) // keyToggle(32)) 
                    v =  2.*scale*worleyD(scale*p);
                    else
                    v= w.y-w.x;	 //  v= 1.-1./(w.y-w.x);
                #endif
                
                return v*d;
                //return smoothstep(thresh-grad/2.,thresh+grad/2.,v*d);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //step1. uv 改為 i.uv , 因為貼圖一定是 1 x 1 矩形, 不必像GLSH一樣局限於瀏覽器長寬
                //step2. iGlobalTime 改為 _Time.y
                //step3. mod 改 fmod  or  #define mod(x,y) (x-y*floor(x/y))
                //step4. lerp 改 lerp
                //step5. frac 改 frac
                //fragCoord.xy -> gl_FragCoord.xy
                //fragColor -> gl_FragColor
                fixed2 uv = i.uv;
                uv = 2.0 * uv - 1.0;

                grad = 0.05+4.*(1.+cos(_Time.y))*.5;
                fixed2 p = i.uv * 2.;
                
                float c0=tweaknoise(p), c=sin(c0*5.);

                fixed3 col; // = fixed3(c);
                col = .5+.5*cos(c0*5.+fixed3(0.,2.*PI/3.,-2.*PI/3.));
                col *= _fixed3(sin(12.*c0)); 
                // col = lerp(col,fixed3(cos(12.*c0)),.5);
                col = lerp(col,_fixed3(c),.5+.5*cos(.13*(_Time.y-6.)));

                return fixed4(col,1.);
            }
            ENDCG
        }
    }
}
