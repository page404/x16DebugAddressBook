
MyData segment
    g_FileName  db 'StuData.txt',00H
	g_Buffer DB 100 DUP (?)
	g_HAND DW ?                     ;�ļ�����
	g_Offset DW 00H                 ;ƫ����
	g_FileEnd   db 0
	BUFFER DB ?                     ;1�ֽڵĻ�����
	;�س� ���� 
    g_strEnter  db 0dh, 0ah, '$'
MyData ends


MyCode5 segment

ShowList proc far ;near
    ;���ݶθ����� ����˵�� �������ݶ�
    assume  cs:MyCode5, ds:MyData

    ;---------�������ݶ�
    mov ax, MyData
    mov ds, ax

    ;----------��ָ�����ļ�
	;�ļ��򿪳ɹ�:AX=�ļ�����
	;�ļ��򿪴���:AX=������
	mov dx,offset g_FileName
	mov al,0      ;AL= 0:��  1:д 3:��/д
	mov ah,3dh    ;21h�е� ���3d�ж�
	int 21h
	JC ERROR        ;������ת
    ;ִ�е������,�ļ����Ž���AX��
    MOV g_HAND,AX     ;�ļ����Ŵ��HAND��

ReadChLoop:
    call ReadCh_M2    ;ÿ��ֻ��ȡһ���ֽ�
	JC ERROR        ;������ת
	CMP AL,g_FileEnd     ;�����ļ���������
	JZ NormalFinish       ;�ǣ�ת
	call ShowCh_M2
	JMP ReadChLoop       ;--------------------------ѭ����ȡ
	
	
ERROR:    ;ֱ�ӽ���

    MOV AH,4CH       ; �����������    AX=���ش���
    INT 21H
	
	ret
	
NormalFinish:

	;---------�ر��ļ�
	;ʧ��:AX=������ 
	MOV BX,g_HAND         ;BXΪҪ��ȡ���ļ�����  
	MOV AH,3EH        ;�ر��ļ�
    INT 21H
	
	;------------��յ�ǰ�ı�׼���뻺����
	;���ڲ���������ڲ���ALΪ0AH����DS:DX����������ַ�����ʼ��
	; mov al,0ah
	; MOV AH,0ch
	; INT 21H
	
    ret 
ShowList endp

ReadCh_M2  PROC           ;ֻ��ȡһ���ֽ�

		;--------��ȡ�ļ�����
		;���ɹ�:   
			;AX=ʵ�ʶ�����ֽ���    
			;AX=0 ��ʾ�ѵ��ļ�β  
		;������:
			;AX=������ 
		mov DX,offset BUFFER   ;g_Buffer ��Ŷ�ȡ��������
		MOV BX,g_HAND         ;BXΪҪ��ȡ���ļ�����
		MOV CX,1        ;CXΪ��ȡ���ֽ���
		MOV AH,3fh        ;3fh ��ȡ�ļ����豸
		INT 21H
		JC ReadChError        ;������ת
		
		CMP AX,CX          ;���ļ��Ƿ���� 
		MOV AL,g_FileEnd     ;�����ļ��Ѿ�����,���ļ������� 
		JB ReadChEnd         ;�ļ�ȷ�ѽ�����ת   ax С�� cx
		MOV AL,BUFFER      ;�ļ�δ������ȡ������

	ReadChEnd:CLC     ;���CFλ 
	ReadChError:RET 

ReadCh_M2 ENDP 

ShowCh_M2 PROC 

    ;�ж��ļ������ȡ�ĵ�ǰ�ַ��Ƿ�Ϊ $
	cmp al,'$'
	jz IsDoller
	cmp al,'*'
	jz IsDoller
	jnz NormalCh
	
NormalCh:
    PUSH DX 
    MOV DL,AL       ;DL���Ҫ������ַ�
    MOV AH,2        ;��ʾ���	DL=����ַ� 
    INT 21H 
    POP DX 
	ret

IsDoller:
	;�س� ���� 
    mov dx, offset g_strEnter
    mov ah, 09h
    int 21h
    ret
ShowCh_M2 ENDP
    
MyCode5 ends

end











































