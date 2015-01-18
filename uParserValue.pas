unit uParserValue;

interface

type

 TValue = class
  strict private
    FText: String;
    FBoundLeft, FBoundRight: Integer;
  protected
    procedure SetText(const Value: String); virtual;
   { function PosFromRight(const ASubStr, AStr: string;
      AOffset: Integer = 0): Integer;
    function PosFromLeft(const ASubStr, AStr: string;
      AOffset: Integer = 1): Integer;}
    // ������ �����-�� ����� ������ ���������
//    function AddValue(const AText: String; const ALeft, ARight: Integer): TValue;
  public
    // ������� � ��������� ��������� ��������� ��������� �������� � ��������
    property Text: String read FText write SetText; // ������������ ����� ���������
    property BoundLeft: Integer read FBoundLeft write FBoundLeft;
    property BoundRight: Integer read FBoundRight write FBoundRight;
    function Value: Double; virtual; abstract;
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TValues = class of TValue;

implementation

constructor TValue.Create;
begin
  inherited;

end;

destructor TValue.Destroy;
begin

  inherited;
end;

procedure TValue.SetText(const Value: String);
begin
  FText := Value;
//  FExpression := StringReplace(FText, ' ', '',[rfReplaceAll]);
end;
// �������� ��� �� ��� Pos, �� � ������,���� ������ ������ 0, ������ ���������
{function TValue.PosFromLeft(const ASubStr, AStr: string;
  AOffset: Integer = 1): Integer;
var
  vStrLen, vSubStrLen: Integer;
  vStrI, vSubStrI: Integer; // ��������
begin
  vStrLen := Length(AStr);
  vSubStrLen := Length(ASubStr);

  for vStrI := AOffset to vStrLen - vSubStrLen do
  begin
    for vSubStrI := 1 to vSubStrLen do
    begin
      // ���� �� ���������, �� ���������� ��������
      if (AStr[vStrI + vSubStrI - vSubStrLen] <> ASubStr[vSubStrI]) then
        Break;
      // ���� ���������� �� �������, �� ���������� ��������
    //  if Self.IsBound(vStrI + vSubStrI - vSubStrLen) then
      //  Break;
      // ���� ����� �������� � �� ��, �� ������� �� ��������� �������
      if vSubStrI = 1 then
          Exit(vStrI - vSubStrLen + 1);
    end;
  end;

  Result := 0;
end; }

// ������ �� �� ��������, ��� � Pos, �� ���� �� ������� ������������ �����
// ������ ������ ��� �� ����� ������� 1, � ��������� Length(s);
// ���� ������ ������ �����, ��� ����, �.�. ������ ���-�� ������������� ��
{function TValue.PosFromRight(const ASubStr, AStr: string;
  AOffset: Integer = 0): Integer;
var
  vStrLen, vSubStrLen: Integer;
  vStrI, vSubStrI: Integer; // ��������
begin
  vStrLen := Length(AStr);
  vSubStrLen := Length(ASubStr);
  if AOffset = 0 then
    AOffset := vStrLen;

  for vStrI := AOffset downto vSubStrLen do
  begin
    for vSubStrI := vSubStrLen downto 1 do
    begin
      // ���� �� ���������, �� ���������� ��������
      if (AStr[vStrI + vSubStrI - vSubStrLen] <> ASubStr[vSubStrI]) then
        Break;
      // ���� ���������� �� �������, �� ���������� ��������
     // if Self.IsBound(vStrI + vSubStrI - vSubStrLen) then
    //    Break;
      // ���� ����� �������� � �� ��, �� ������� �� ��������� �������
      if vSubStrI = 1 then
          Exit(vStrI - vSubStrLen + 1);
    end;
  end;

  Result := 0;
end; }

end.
