unit uConstantGroup;

interface

uses
  System.SysUtils,
  uParserValue;

type
  // ����������� ��������, ���������� ��� ���������
  TConstantValue = class(TValue)
  public
    constructor Create(const AValue: String); reintroduce; virtual;
  end;

  TVariable = class(TConstantValue)
  strict private
    FPlacedValue: Double;
    FPlaced: Boolean;
    function GetName: string;// ������ ������ Text
  public
    property Name: string read GetName; // �������� ��� �� ���� ����� ����������
    procedure PlaceValue(const AValue: Double);
    function Value: Double; override;
    constructor Create(const AValue: String); override;
  end;

  TDouble = class(TConstantValue)
  public
    function Value: Double; override;
  end;

implementation

{ TVariable }

constructor TVariable.Create(const AValue: String);
begin
  inherited;
  Text := AValue;
  FPlaced := False;
  Self.BoundLeft := 1;
  Self.BoundRight := Length(AValue)
end;

function TVariable.GetName: string;
begin
  Result := Self.Text;
end;

procedure TVariable.PlaceValue(const AValue: Double);
begin
  FPlaced := True;
  FPlacedValue := AValue;
end;

function TVariable.Value: Double;
begin
  if FPlaced then
    Result := FPlacedValue
  else
    raise Exception.Create('�� ������ �������� ���������� �' + Name + '�');
end;

{ TDouble }

function TDouble.Value: Double;
var
  vA: Double;
  vErr: Integer;
begin
  Val(Text, vA, vErr);

  if vErr = 0 then
    Result := vA
  else
    raise Exception.Create('������ ������������� ��������, ���������� ��������� � ����� � ��������� ������ �' + Text + '�');
end;

{ TConstantValue }

constructor TConstantValue.Create(const AValue: String);
begin
  Text := AValue;
end;

end.
