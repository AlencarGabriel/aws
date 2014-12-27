{
    AWS
    Copyright (C) 2013-2014 by mdbs99

    See the file LICENSE.txt, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
unit aws_client;

{$i aws.inc}

interface

uses
  //rtl
  sysutils,
  classes,
  //synapse
  synacode,
  synautil,
  //aws
  aws_auth,
  aws_http;

type
  IAWSResponse = IHTTPResponse;

  IAWSRequest = interface(IInterface)
    function Method: string;
    function Name: string;
    function Resource: string;
    function SubResource: string;
    function ContentType: string;
    function ContentMD5: string;
    function CanonicalizedAmzHeaders: string;
    function CanonicalizedResource: string;
    function Stream: TStream;
    function ToString: string;
  end;

  IAWSClient = interface(IInterface)
    function Send(Request: IAWSRequest): IAWSResponse;
  end;

  TAWSResponse = THTTPResponse;

  TAWSRequest = class(TInterfacedObject, IAWSRequest)
  private
    FMethod: string;
    FName: string;
    FResource: string;
    FSubResource: string;
    FContentType: string;
    FContentMD5: string;
    FCanonicalizedAmzHeaders: string;
    FCanonicalizedResource: string;
    FStream: TStream;
  public
    constructor Create(const Method, AName, Resource, SubResource, ContentType, ContentMD5,
      CanonicalizedAmzHeaders, CanonicalizedResource: string; Stream: TStream);
    constructor Create(const Method, AName, Resource, SubResource, ContentType, ContentMD5,
      CanonicalizedAmzHeaders, CanonicalizedResource: string);
    constructor Create(const Method, AName, Resource, SubResource, CanonicalizedResource: string);
    constructor Create(const Method, AName, Resource, CanonicalizedResource: string);
    constructor Create(const Method, AName, Resource, CanonicalizedResource: string; Stream: TStream);
    constructor Create(const Method, AName, CanonicalizedResource: string);
    function Method: string;
    function Name: string;
    function Resource: string;
    function SubResource: string;
    function ContentType: string;
    function ContentMD5: string;
    function CanonicalizedAmzHeaders: string;
    function CanonicalizedResource: string;
    function Stream: TStream;
    function ToString: string; override;
  end;

  TAWSClient = class sealed(TInterfacedObject, IAWSClient)
  private const
    AWS_URI = 's3.amazonaws.com';
  private
    FCredentials: IAWSCredentials;
  protected
    function MakeURI(const AName, Query: string): string;
    function MakeAuthHeader(const Method, ContentType, ContentMD5,
      CanonicalizedAmzHeaders, CanonicalizedResource: string): string;
  public
    constructor Create(const Credentials: IAWSCredentials);
    function Send(Request: IAWSRequest): IAWSResponse;
  end;

implementation

{ TAWSRequest }

constructor TAWSRequest.Create(const Method, AName, Resource, SubResource,
  ContentType, ContentMD5, CanonicalizedAmzHeaders,
  CanonicalizedResource: string; Stream: TStream);
begin
  FMethod := Method;
  FName := AName;
  FResource := Resource;
  FSubResource := SubResource;
  FContentType := ContentType;
  FContentMD5 := ContentMD5;
  FCanonicalizedAmzHeaders := CanonicalizedAmzHeaders;
  FCanonicalizedResource := CanonicalizedResource;
  FStream := Stream;
end;

constructor TAWSRequest.Create(const Method, AName, Resource, SubResource,
  ContentType, ContentMD5, CanonicalizedAmzHeaders,
  CanonicalizedResource: string);
begin
  Create(
    Method, AName, Resource, SubResource, ContentType,
    ContentMD5, CanonicalizedAmzHeaders, CanonicalizedResource, nil);
end;

constructor TAWSRequest.Create(const Method, AName, Resource, SubResource,
  CanonicalizedResource: string);
begin
  Create(Method, AName, Resource, SubResource, '', '', '', CanonicalizedResource, nil);
end;

constructor TAWSRequest.Create(const Method, AName, Resource,
  CanonicalizedResource: string);
begin
  Create(Method, AName, Resource, '', '', '', '', CanonicalizedResource, nil);
end;

constructor TAWSRequest.Create(const Method, AName, Resource,
  CanonicalizedResource: string; Stream: TStream);
begin
  Create(Method, AName, Resource, '', '', '', '', CanonicalizedResource, Stream);
end;

constructor TAWSRequest.Create(const Method, AName, CanonicalizedResource: string);
begin
  Create(Method, AName, '', '', '', '', '', CanonicalizedResource, nil);
end;

function TAWSRequest.Method: string;
begin
  Result := FMethod;
end;

function TAWSRequest.Name: string;
begin
  Result := FName;
end;

function TAWSRequest.Resource: string;
begin
  Result := FResource;
end;

function TAWSRequest.SubResource: string;
begin
  Result := FSubResource;
end;

function TAWSRequest.ContentType: string;
begin
  Result := FContentType;
end;

function TAWSRequest.ContentMD5: string;
begin
  Result := FContentMD5;
end;

function TAWSRequest.CanonicalizedAmzHeaders: string;
begin
  Result := FCanonicalizedAmzHeaders;
end;

function TAWSRequest.CanonicalizedResource: string;
begin
  Result := FCanonicalizedResource;
end;

function TAWSRequest.Stream: TStream;
begin
  Result := FStream;
end;

function TAWSRequest.ToString: string;
begin
  with TStringList.Create do
  try
    Add('Method=' + FMethod);
    Add('Resource=' + FResource);
    Add('SubResource=' + FSubResource);
    Add('ContentType=' + FContentType);
    Add('ContentMD5=' + FContentMD5);
    Add('CanonicalizedAmzHeaders=' + FCanonicalizedAmzHeaders);
    Add('CanonicalizedResource=' + FCanonicalizedResource);
    Result := Text;
  finally
    Free;
  end;
end;

{ TAWSClient }

function TAWSClient.MakeURI(const AName, Query: string): string;
begin
  Result := '';
  if FCredentials.UseSSL then
    Result += 'https://'
  else
    Result += 'http://';
  if AName <> '' then
    Result += AName + '.';
  Result += AWS_URI + Query;
end;

function TAWSClient.MakeAuthHeader(const Method, ContentType, ContentMD5,
  CanonicalizedAmzHeaders, CanonicalizedResource: string): string;
var
  H: string;
  DateFmt: string;
begin
  DateFmt := RFC822DateTime(Now);
  H := Method + #10
     + ContentMD5 + #10
     + ContentType + #10
     + DateFmt + #10
     + CanonicalizedAmzHeaders
     + CanonicalizedResource;
  Result := 'Date: ' + DateFmt + #10
          + 'Authorization: AWS '
          + FCredentials.GetAccessKeyId + ':' + EncodeBase64(HMAC_SHA1(H, FCredentials.GetSecretKey));
end;

constructor TAWSClient.Create(const Credentials: IAWSCredentials);
begin
  inherited Create;
  FCredentials := Credentials;
end;

function TAWSClient.Send(Request: IAWSRequest): IAWSResponse;
var
  H: string;
  Snd: IHTTPSender;
begin
  H := MakeAuthHeader(
    Request.Method, Request.ContentType, Request.ContentMD5,
    Request.CanonicalizedAmzHeaders, Request.CanonicalizedResource);
  Snd := THTTPSender.Create(
    Request.Method, H, Request.ContentType,
    MakeURI(Request.Name, Request.Resource),
    Request.Stream);
  Result := Snd.Send;
end;

end.
