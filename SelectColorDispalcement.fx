#define AA_FLG 1
//edit by KarlvonDonitz

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

float scaling : CONTROLOBJECT < string name = "(self)"; >;
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

texture EdgeRT: OFFSCREENRENDERTARGET <
   
    float4 ClearColor = { 0, 0, 0, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = 0;
    string DefaultEffect = 
        "* = White.fx";
>;

texture WB2: OFFSCREENRENDERTARGET <
   
    float4 ClearColor = { 0, 0, 0, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = 0;
    string DefaultEffect = 
        "* = White.fx";
>;

struct VS_OUTPUT {
    float4 Pos			: POSITION;
	float2 Tex			: TEXCOORD0;
};



sampler EdgeView = sampler_state {
    texture = <EdgeRT>;
    AddressU  = CLAMP;
    AddressV = CLAMP;
    Filter = NONE;
};

sampler displacementmap = sampler_state {
    texture = <WB2>;
    AddressU  = CLAMP;
    AddressV = CLAMP;
    Filter = NONE;
};

VS_OUTPUT VS_passMain( float4 Pos : POSITION, float4 Tex : TEXCOORD0 ){
    VS_OUTPUT Out = (VS_OUTPUT)0; 

    Out.Pos = Pos; 
    Out.Tex = Tex;
    return Out;
}

float4 PS_passMain(float2 Tex: TEXCOORD0) : COLOR
{   
    float4 Color = 1;
	float4 ColorSamp=1;
	float4 ScnColor = tex2D(ScnSamp,Tex);
    float EdgeSamp= tex2D(EdgeView,Tex);
	float2 Tex0=Tex;
	Tex0.x += ((sin(Tex.y*300+time*5)*3+cos(Tex.y*100+time)*2+sin(Tex.y*250+time*5))+3)/scaling;
	float4 DisplacementColor = tex2D(displacementmap,Tex0);
	EdgeSamp *= DisplacementColor;
	Color = float4(0,0,0,1);
	if (EdgeSamp == 0) {
	Tex.x += ((sin(Tex.y*300+time*5)*3+cos(Tex.y*100+time)*2+sin(Tex.y*250+time*5))+3)/scaling;
	ColorSamp = tex2D(ScnSamp,Tex);
	} else {
	ColorSamp = ScnColor;
	}
	Color= ColorSamp*Transparent+ScnColor*(1-Transparent);
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