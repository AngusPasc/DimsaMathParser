unit uExpressionParser;

interface

uses
  System.SysUtils, System.StrUtils,
  Generics.Collections, System.RegularExpressions,
  uTextProc, uParserValue, uNamedList;

type
  {������ ���������}
  TExpression = class(TValue)
  strict private
    FValues: TList<TValue>;
    FValueStack: TValueStack; // ����, ������ ������ ����� �������� ����������
    function LeftExp(APos: Integer): TValue; virtual;
    function RightExp(APos: Integer): TValue; virtual;
    function OuterBrackets: TList<TStrAndPos>; virtual;
  protected
    FParsed: Boolean; // ����������, ��������� �� ���������.
    FExpression: String; // � ������� �� ������������� ������ �� ����� ������ ��������
    property Values: TList<TValue> read FValues; // ������������ ��������, ������������� ����� ��������
    function IsBound(const APos: Integer): Boolean; virtual; // ������������ ��������� ��� ���������, �� �������� �� ����� �������� � ������� ������ �� ������������
    function WhatBound(const APos: Integer): TValue; virtual; // ����, ��� IsBound, ������ ���� ���������
    function TypeOfValue(const AText: String): TValues; virtual;
    procedure DeleteSurfaceBrackets(var AText: String);
    procedure ParseOperands; virtual; // ������� ��� ��������
    procedure ParseOuterFunctions; virtual; // ������� ��� �������
    procedure ParseOuterBrackets; virtual; // ������� ��� ������ ������
    procedure SetText(const Value: String); override;
    function AddConstantValue(const AText: string; const ALeft, ARight: Integer): TValue; virtual; // ��������� ��������� ��� ����������
    //function IsOperand(ch: Char): Boolean; virtual;
    //function DeepBrackets: TList<TStrAndPos>; virtual;
  public
    property Expression: string read FExpression; // ���������� �����
    property ValueStack: TValueStack read FValueStack write FValueStack;
    function Value: Double; override;
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

uses
  uOperandGroup, uConstantGroup, uFunctionGroup;

{ TExpression }

function TExpression.AddConstantValue(const AText: string; const ALeft, ARight: Integer): TValue;
var
  vTmp: TValue;
begin
  vTmp := TypeOfValue(AText).Create;
  vTmp.Text := AText;
  // ���� ��� ����������, ���������� ��������� ���� ���
  if vTmp is TVariable then
  begin
    // ����� ��������� ����� �����, ����� �� ���� ���������, �� ��� �� ����� ��������
    // FValueStack.Add(vTmp.Text, 0);
    TVariable(vTmp).ValueStack := FValueStack;
  end;
  vTmp.BoundLeft := ALeft;
  vTmp.BoundRight :=  ARight;
  Result := vTmp;
end;

constructor TExpression.Create;
begin
  inherited;
  FValues := TList<TValue>.Create;
  FParsed := False;
//  FValueStack := TValueStack.Create;
end;

procedure TExpression.DeleteSurfaceBrackets(var AText: String);
var
  i, vN: Integer;
  vLevel: Integer;
begin
  vN := Length(AText);

  if (AText[1] = '(') and (AText[Length(AText)] = ')') then
  begin
    vLevel := 1;
    for i := 2 to vN-1 do
    begin
      if AText[i] = '(' then
        vLevel := vLevel + 1;
      if AText[i] = ')' then
        vLevel := vLevel - 1;

      if vLevel <= 0 then
        Exit;
    end;

    if vLevel = 1 then
    begin
      Delete(AText, 1, 1);
      Delete(AText, Length(AText), 1);
      DeleteSurfaceBrackets(AText);
    end;
  end;

end;

function TExpression.OuterBrackets: TList<TStrAndPos>;
var
  vRes: TList<TStrAndPos>;
  i, vN: Integer; // ������ ��������
  vBrCur: Integer; // ������������ ������� ������ � �������
  vStr: TStrAndPos;
begin
  vRes := TList<TStrAndPos>.Create;

  vN := Length(FExpression);
  vBrCur := 0;
  for i := 1 to vN do
  begin
    // ���� ������� ������, ����������� ������� �����������
    if FExpression[i] = '(' then
    begin
      vBrCur := vBrCur + 1;
      if (vBrCur = 1) then
      begin
        vStr.Text := '';
        vStr.StartPos := i;
      end;
    end;

    // ���� ������� ������� ������ 1, �� ��������� ��� ��� ������ ������
    if (vBrCur >= 1) then
      vStr.Text := vStr.Text + FExpression[i];

    // ���� ������ �����������, ��������� ������� �����������
    if (FExpression[i] = ')') then
    begin
      if (vBrCur = 1) then
      begin
        vStr.EndPos := i;
        vRes.Add(vStr);
      end;
      vBrCur := vBrCur - 1;

      if vBrCur < 0 then
        raise Exception.Create('������ ��������� ��������� �' + FExpression + '�. ������������ ��������� ����������� ������');
    end;
  end;

  if vBrCur <> 0 then
    raise Exception.Create('������ ��������� ��������� �' + FExpression + '�. ������ � ���������� ������������� � ������������� ������');
  Result := vRes;
end;

procedure TExpression.ParseOuterBrackets;
var
  vList: TList<TStrAndPos>;
  vTmp: TExpression;
  i, vN: Integer;
begin
  vList := Self.OuterBrackets;
  vN := vList.Count - 1;

  for i := 0 to vN do
    if Not IsBound(vList[i].StartPos) then
    begin
      vTmp := TExpression.Create;
      vTmp.ValueStack :=Self.ValueStack;
      vTmp.BoundLeft := vList[i].StartPos;
      vTmp.BoundRight := vList[i].EndPos;
      vTmp.Text := Copy(Expression, vTmp.BoundLeft, vTmp.BoundRight - vTmp.BoundLeft + 1);
      Values.Add(vTmp);
    end;
 //   Self.AddExpression(vList[i].StartPos, vList[i].EndPos);
end;

procedure TExpression.ParseOuterFunctions;
var
  vList: TList<TStrAndPos>;
  i, vN, j: Integer;
  vTmp: TFunction;
begin
  vList := OuterBrackets;
  vN := vList.Count - 1;

  for i := 0 to vN do
    for j := 0 to CFuncNamesCount - 1 do
    begin
     // vFN := Copy(FExpression, vList[i].StartPos - Length(CFuncNames[j]), Length(CFuncNames[j]));
      if
        LowerCase(Copy(
          FExpression,
          vList[i].StartPos - Length(CFuncNames[j]),
          Length(CFuncNames[j])
        )) = CFuncNames[j]
       then
       begin
         // ������� ��������� �������
         vTmp := CFastFuncNames[j].Create;
         vTmp.ValueStack :=Self.ValueStack;
         vTmp.BoundLeft := vList[i].StartPos - Length(CFuncNames[j]);
         vTmp.BoundRight := vList[i].EndPos;
         vTmp.Text := Copy(Expression, vTmp.BoundLeft, vTmp.BoundRight - vTmp.BoundLeft + 1);
         Values.Add(vTmp);
       end;
    end;
end;

destructor TExpression.Destroy;
begin
  FValues.Free;
  inherited;
end;

function TExpression.Value: Double;
var
  vTmp: TValue;
begin
  if Not FParsed then
  begin
    // ������� ��� ������� � ������ ������. ������: sin(45+90)
    ParseOuterFunctions;
    // ��� ���������� ������ �������� ������ ������������
    ParseOuterBrackets;
    // ������ ���, ���� ���� ������ � ��� �������� ������� ������
    // � ������ ��������
    ParseOperands;

    // ���� ��� �� ������ ��������, �� �����  �������, �� ������� ���������
    if Self.Values.Count <= 0 then
    begin
      vTmp := AddConstantValue(FExpression, 1, Length(FExpression));
      Self.Values.Add(vTmp);
    end;
  end;

  Result := Self.Values[Self.Values.Count - 1].Value;    
end;

function TExpression.LeftExp(APos: Integer): TValue;
var
  i: Integer;
  vPos: Integer;
  vTmp: TValue;
  ch: String;
  vText: String;
  vLeft, vRight: Integer;
  vPosMax: Integer;
  vOp: Integer; // ����� ��������
begin
  vTmp := WhatBound(APos);
  // ���� ������ � ��� ������������ Value, �� ������ ���
  // ����� ������ ������������� ��������
  if vTmp <> Nil then
    Exit(vTmp);

  vOp := 0;
  vPosMax := -1;
  for i := 0 to  OperandCharCount - 1 do
  begin
    //���� ��� ��������� ����� ��������� ������
    vPos := PosFromRight(OperandChar[i], Expression, APos);
    if vPos > 0 then
      if (vPosMax = -1) or (vPos > vPosMax)then
      begin
        vPosMax:= vPos;
        vOp := i; // ���������� ����� ����� � �������
      end;
  end;

  if vPosMax > 0 then
  begin
    vPos := vPosMax;
    vPos := vPos + Length(OperandChar[vOp]);
    ch := Expression[vPos];
    // �.�. ���� �������� ������� ��, � �� ������ ���������
    vLeft := vPos;
    vRight := APos;
    vText := Copy(FExpression, vLeft, vRight - vLeft + 1);
    vTmp := AddConstantValue(vText, vLeft, vRight);
    Exit(vTmp);
  end;

  // ���� �� ����� �� ����� �����, �� �� ����� ��� ������ ��������� ��� ���� ���������
  if APos <= 0 then
    raise Exception.Create('����� ��������� �� ' + IntToStr(APos) + ' ������� �� ����������.');

  vLeft := 1;
  vRight := APos;
  vText := Copy(FExpression, vLeft, vRight - vLeft + 1);
  vTmp := AddConstantValue(vText, vLeft, vRight);
  Exit(vTmp);

end;

function TExpression.RightExp(APos: Integer): TValue;
var
  i: Integer;
  vPos, vPosMin: Integer;
  vTmp: TValue;
  vText: String;
  vLeft, vRight: Integer;
begin
  vTmp := WhatBound(APos);
  // ���� ������ � ��� ������������ Value, �� ������ ���
  // ����� ������ ������������� ��������
  if vTmp <> Nil then
    Exit(vTmp);

  vPosMin := -1;
  for i := 0 to OperandCharCount - 1 do
  begin
    vPos := PosFromLeft(OperandChar[i], Expression, APos);
    if vPos > 0 then
      if (vPosMin = -1) or ((vPos < vPosMin)) then
        vPosMin := vPos;
  end;


  if vPosMin > 0 then
  begin
    vPos := vPosMin;
    vLeft := APos;
    vRight := vPos - 1;
    vText := Copy(FExpression, vLeft, vRight - vLeft + 1);
    vTmp := AddConstantValue(vText, vLeft, vRight);
    Exit(vTmp);
  end;

  // ���� �� ����� �� ����� �����, �� �� ����� ��� ������ ��������� ��� ���� ���������
  if APos > Length(Expression) then
    raise Exception.Create('������ ��������� �� ' + IntToStr(APos) + ' ������� �� ����������.');

  vLeft := APos;
  vRight := Length(FExpression);
  vText := Copy(FExpression, vLeft, vRight - vLeft + 1);
  vTmp := AddConstantValue(vText, vLeft, vRight);
  Exit(vTmp);
end;

procedure TExpression.SetText(const Value: String);
begin
  inherited;
  FExpression := StringReplace(Text, ' ', '',[rfReplaceAll]);
  FParsed := False;
  DeleteSurfaceBrackets(FExpression);
end;

function TExpression.TypeOfValue(const AText: String): TValues;
var
  vReg: TRegEx;
  vA: Double;
  vErr: Integer;
  vPattern: String;
begin
  // ���������, ����� �� ���
  Val(AText, vA, vErr);
  if vErr = 0 then
    Exit(TDouble);

  // ���� �� �����, �� ��������� �� ���������� �������
  vPattern := '[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_\.\-]';
  vReg := TRegEx.Create(vPattern);
  if vReg.IsMatch(AText) then
    Result := TVariable
  else
    raise Exception.Create('������ ��������� ���������� �'+ AText +'�. �������� �� ������������� ����������� ��������� '+ vPattern);
end;

procedure TExpression.ParseOperands;
var
  j, i, vN: Integer;
  vTmp: TOperand;
  vList: TList<Integer>;
  vValLeft, vValRight: TValue;
begin
  // ������� ��� �������
   vN := Length(Operands) - 1;

  for i := 0 to vN do
  begin
    vList := ListOfPos(Operands[i], Expression);
    for j := 0 to vList.Count - 1 do
      if Not IsBound(vList[j]) then
      begin
        vValLeft := LeftExp(vList[j] - 1);
        vValRight := RightExp(vList[j] + 1);
        vTmp := FastOperandClass[i].Create(vValLeft, vValRight);

        vTmp.BoundLeft := vValLeft.BoundLeft;
        vTmp.BoundRight := vValRight.BoundRight;
        vTmp.Text := Copy(FExpression, vValLeft.BoundLeft, vValRight.BoundRight - vValLeft.BoundLeft + 1);

        Self.Values.Add(vTmp);
      end;
  end;

end;

function TExpression.IsBound(const APos: Integer): Boolean;
var
  vN, I: Integer;
begin
  vN := FValues.Count - 1;
//                TExpression
  for i := vN downto 0 do
    if (APos >= FValues[i].BoundLeft) and (APos <= FValues[i].BoundRight) then
      Exit(True);
  Result := False;
end;

function TExpression.WhatBound(const APos: Integer): TValue;
var
  vN, I: Integer;
begin
  vN := FValues.Count - 1;

  for i := vN downto 0 do
    if (APos >= FValues[i].BoundLeft) and (APos <= FValues[i].BoundRight) then
      Exit(FValues[i]);
  Result := Nil;
end;

{function TExpression.IsOperand(ch: Char): Boolean;
var
  i: Integer;
begin
  for i := 0 to OperandCharCount - 1 do
    if ch = OperandChar[i] then exit(True);
  Result := False;
end;}

{function TExpression.AddFunction(const AType: TValues; const ALeft, ARight: Integer): TValue;
var
  vTmp: TFunction;
begin
  vTmp := AType.Create;
  vTmp.BoundLeft := ALeft;
  vTmp.BoundRight := ARight;
  vTmp.Text := Copy(Expression, ALeft, ARight - ALeft + 1);
  Values.Add(vTmp);
  Result := vTmp;
end;}

{function TExpression.DeepBrackets: TList<TStrAndPos>;
var
  vRes: TList<TStrAndPos>;
  i, vN: Integer; // ������ ��������
  j, vNBr: Integer; // ������ ������
  vBrMax, vBrCur: Integer; // ������������ ������� ������ � �������
  vStr: TStrAndPos;
begin
  vRes := TList<TStrAndPos>.Create;
  vStr.Text := FExpression;
  vStr.StartPos := 1;
  vStr.EndPos := Length(FExpression);
  vRes.Add(vStr);

  vN := Length(FExpression);
  vBrMax := 0;
  vBrCur := 0;
  for i := 1 to vN do
  begin
    // ���� ������� ������, ����������� ������� �����������
    if FExpression[i] = '(' then
    begin
      vBrCur := vBrCur + 1;
      // ���� ������������ ������� ������ ��������, ������ ��� ���������� ������
      // � ��������� ����� ��������
      if vBrMax < vBrCur then
      begin
        vRes.Clear;
        vBrMax := vBrCur;
      end;
      vStr.Text := '';
      vStr.StartPos := i;
    end;

    // ���� ������� ������� ������ ����� �������������, �� ��������� ��� ��� ������ ������
    if vBrMax = vBrCur then
      vStr.Text := vStr.Text + FExpression[i];

    // ���� ������ �����������, ��������� ������� �����������
    if FExpression[i] = ')' then
    begin
      vStr.EndPos := i;
      if vBrMax = vBrCur then
        vRes.Add(vStr);
      vBrCur := vBrCur - 1;
      if vBrCur < 0 then
        raise Exception.Create('������ ��������� ��������� �' + FExpression + '�. ������������ ��������� ����������� ������');
    end;
  end;

  if vBrCur <> 0 then
    raise Exception.Create('������ ��������� ��������� �' + FExpression + '�. ������ � ���������� ������������� � ������������� ������');
  Result := vRes;
end;}

end.
