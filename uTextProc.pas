unit uTextProc;

interface

uses
  System.SysUtils, System.Generics.Collections;

  function PosFromRight(const ASubStr, AStr: string; AOffset: Integer = 0): Integer;
  function PosFromLeft(const ASubStr, AStr: string;  AOffset: Integer = 1): Integer;
  function ListOfPos(const ASubstr, AStr: String): TList<Integer>;

type
  {�������� ��� �������� �������}
  TStrAndPos = record
    Text: string;
    StartPos, EndPos: Integer;
  end;

implementation

// ���� ������ �������� ��������� ���������
function ListOfPos(const ASubstr, AStr: String): TList<Integer>;
var
  vPos: Integer;
  vRes: TList<Integer>;
//  vN, vArr: Integer;
begin
  vPos := 0;
  vRes := TList<Integer>.Create;
  repeat
    vPos := Pos(ASubstr, AStr, vPos + 1);
    if vPos > 0 then
      vRes.Add(vPos);
  until vPos <= 0;

  Result := vRes;
end;

// ������ �� �� ��������, ��� � Pos, �� ���� �� ������� ������������ �����
// ������ ������ ��� �� ����� ������� 1, � ��������� Length(s);
// ���� ������ ������ �����, ��� ����, �.�. ������ ���-�� ������������� ��
function PosFromRight(const ASubStr, AStr: string; AOffset: Integer = 0): Integer;
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
      // ���� ����� �������� � �� ��, �� ������� �� ��������� �������
      if vSubStrI = 1 then
          Exit(vStrI - vSubStrLen + 1);
    end;
  end;

  Result := 0;
end;

// �������� ��� �� ��� Pos, �� � ������,���� ������ ������ 0, ������ ���������
function PosFromLeft(const ASubStr, AStr: string; AOffset: Integer = 1): Integer;
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
      // ���� ����� �������� � �� ��, �� ������� �� ��������� �������
      if vSubStrI = 1 then
          Exit(vStrI - vSubStrLen + 1);
    end;
  end;

  Result := 0;
end;

end.
