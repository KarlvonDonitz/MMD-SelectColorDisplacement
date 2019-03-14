#define AA_FLG 0
//edit by KarlvonDonitz

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

float Intensity : CONTROLOBJECT < string name = "(self)"; string item = "Si";>;
float Frequency : CONTROLOBJECT < string name = "(self)"; string item = "X";>;
float Speed : CONTROLOBJECT < string name = "(self)"; string item = "Y";>;
float Value1 : CONTROLOBJECT < string name = "(self)"; string item = "Rx";>;
float Value2 : CONTROLOBJECT < string name = "(self)"; string item = "Ry";>;
float Block : CONTROLOBJECT < string name = "(self)"; string item = "Tr";>;
float time: TIME;
float2 ViewportSize : VIEWPORTPIXELSIZE;
float Transparent : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;

static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;

static float2 SampStep = (float2(1,1)/ViewportSize);


float4 ClearColor = {0,0,0,1};
float ClearDepth  = 1.0;


texture2D ScnMap : RENDERCOLORTARGET <

    int MipLevels = 1;
    bool AntiAlias = AA_FLG;
    string Format = "A8R8G8B8" ;
>;
sampler2D ScnSamp = sampler_state {
    texture = <ScnMap>;
    AddressU  = CLAMP;
    AddressV = CLAMP;
    Filter = NONE;
};

texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    string Format = "D24S8";
>;

texture ColorMask: OFFSCREENRENDERTARGET <
    string Description = "Color Mask for SelectColorDisplacement.fx";
    float4 ClearColor = { 0, 0, 0, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = 0;
    string DefaultEffect = 
        "* = OFF.fx";
>;

sampler Mask = sampler_state {
	texture = <ColorMask>;
	AddressU = CLAMP;
	AddressV = CLAMP;
	Filter = NONE;
};

float4 permute(float4 x)
{
	return ((x*34.0) + 1.0)*x - floor(((x*34.0) + 1.0)*x / 289.0) * 289.0;
}

float4 taylorInvSqrt(float4 r)
{
	return (float4)1.79284291400159 - r * 0.85373472095314;
}

float pnoise(float2 P, float2 rep)
{
	float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
	float4 Pf = frac(P.xyxy) - float4(0.0, 0.0, 1.0, 1.0);
	Pi = Pi - rep.xyxy * floor(Pi / rep.xyxy);
	Pi = Pi - floor(Pi / 289.0) * 289.0;
	float4 ix = Pi.xzxz;
	float4 iy = Pi.yyww;
	float4 fx = Pf.xzxz;
	float4 fy = Pf.yyww;

	float4 i = permute(permute(ix) + iy);

	float4 gx = frac(i / 41.0) * 2.0 - 1.0;
	float4 gy = abs(gx) - 0.5;
	float4 tx = floor(gx + 0.5);
	gx = gx - tx;

	float2 g00 = float2(gx.x, gy.x);
	float2 g10 = float2(gx.y, gy.y);
	float2 g01 = float2(gx.z, gy.z);
	float2 g11 = float2(gx.w, gy.w);

	float4 norm = taylorInvSqrt(float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
	g00 *= norm.x;
	g01 *= norm.y;
	g10 *= norm.z;
	g11 *= norm.w;

	float n00 = dot(g00, float2(fx.x, fy.x));
	float n10 = dot(g10, float2(fx.y, fy.y));
	float n01 = dot(g01, float2(fx.z, fy.z));
	float n11 = dot(g11, float2(fx.w, fy.w));

	float2 fade_xy = Pf.xy*Pf.xy*Pf.xy*(Pf.xy*(Pf.xy*6.0 - 15.0) + 10.0);
	float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
	float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
	return 2.3 * n_xy;
}


struct VS_OUTPUT {
    float4 Pos			: POSITION;
	float2 Tex			: TEXCOORD0;
};


VS_OUTPUT VS_passMain( float4 Pos : POSITION, float4 Tex : TEXCOORD0 ){
    VS_OUTPUT Out = (VS_OUTPUT)0; 

    Out.Pos = Pos; 
    Out.Tex = Tex;
    return Out;
}

float4 PS_passMain(float2 Tex: TEXCOORD0) : COLOR
{   
	float4 Color = tex2D(ScnSamp,Tex);
    float MaskSamp= tex2D(Mask,Tex);
	double DisplacementValue = lerp(0,Intensity,pnoise(float2(1,Tex.y*Frequency+time*Speed),float2(Value1,Value2)));
	double BlockDisplacementValue = double(int(DisplacementValue*100))/100;
	if (Block ==0) {
    DisplacementValue = BlockDisplacementValue;
    }
    Tex.x += DisplacementValue;
	float DisplacementColor = tex2D(Mask, Tex);
	MaskSamp *= DisplacementColor;
	if (MaskSamp == 0)
	{
		Color = tex2D(ScnSamp, Tex);
	}
    return Color;
}

technique Color <
    string Script = 
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "ScriptExternal=Color;"
        
        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "Pass=Main;"
    ;
> {

    pass Main < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS_passMain();
        PixelShader  = compile ps_3_0 PS_passMain();
    }
}
