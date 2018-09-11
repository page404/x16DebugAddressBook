
MyData segment
    g_FileName  db 'StuData.txt',00H
	g_Buffer DB 100 DUP (?)
	g_HAND DW ?                     ;�ļ�����
	g_Offset DW 00H                 ;ƫ����
	g_FileEnd   db 0
	BUFFER DB ?                     ;1�ֽڵĻ�����
	;�س� ���� 
    g_strEnter  db 0dh, 0ah, '$'
	
	;-------------����������صĸ�ʽ  ����1���ַ�
	g_dbSize_OneCh    db 2                 ;��һ���ֽ�Ϊ�������Ĵ�С(����������󳤶�)    ���������Χ,DOS��������,����������
    g_dbLength_OneCh  db 0                   ;�ڶ����ֽ�Ϊʵ�ʵĳ��� (���������,�Զ���д)
    g_strBuffer_OneCh db 2 dup (0)         ;�ӵ������ֽڿ�ʼ,ΪBuffer
	
	
	g_deleteTip db 'input delete index:$'
	g_currentIndex db 0     ;��ǰ���ҵ����ļ��ĵڼ���λ��
	g_currentDollarIndex db 0   ;��ǰ��ȡ�����ļ��еڼ��� $ ��λ��
	g_deleteIndex db 0    ;Ҫɾ����¼���±�λ��,�±��0��ʼ��(��1��$ǰg_deleteIndexΪ0)
	g_deleteStartIndex db 0  ;Ҫɾ�����ļ���ʼλ��
	g_deleteEndIndex db 0    ;Ҫɾ�����ļ�����λ��
	g_isAllowSet_deleteStartIndex db 1    ;1:�������� 0:����������    
	g_finish db 0   ;0:��������  1:�Ѿ����ҵ��±�λ��,ֱ�ӷ��غ���
MyData ends


MyCode9 segment

DeleteRange proc far ;near
    ;���ݶθ����� ����˵�� �������ݶ�
    assume  cs:MyCode9, ds:MyData

    ;---------�������ݶ�
    mov ax, MyData
    mov ds, ax
	
	;����Ļ����� input delete index:
    mov dx, offset g_deleteTip
    mov ah, 09h
    int 21h
	
	;-------------�ȴ��û�����
	;DS:DX=�������׵�ַ
	;(DS:DX+1)=ʵ��������ַ���
	;(DS:DX)=����������ַ���
    mov dx, offset g_dbSize_OneCh
    mov ah, 0ah  ;0ah ��ʾ�������뵽������
    int 21h
	
	;------����ɾ���ڼ�����¼
	mov bp,offset g_strBuffer_OneCh
	xor ax,ax
	mov al,ds:[bp]   ;ax ΪҪɾ����¼���±�
	mov bx,offset g_deleteIndex
	mov byte ptr ds:[bx],al
	

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
    call ReadCh_M4    ;ÿ��ֻ��ȡһ���ֽ�
	JC ERROR        ;������ת
	CMP AL,g_FileEnd     ;�����ļ���������
	JZ NormalFinish       ;�ǣ�ת
	call ShowCh_M4
	mov bx,offset g_finish
	xor ax,ax
	mov al,byte ptr ds:[bx]
	cmp ax,1
	jz NormalFinish
	JMP ReadChLoop       ;--------------------------ѭ����ȡ
	
	
ERROR:    ;ֱ�ӽ���
    MOV AH,4CH       ; �����������    AX=���ش���
    INT 21H
	
NormalFinish:
	;---------�ر��ļ�
	;ʧ��:AX=������ 
	MOV BX,g_HAND         ;BXΪҪ��ȡ���ļ�����  
	MOV AH,3EH        ;�ر��ļ�
    INT 21H
	
	;--------------------- �� Ҫɾ����¼�� ��ʼλ�� �� ����λ�� �ŵ�ax��,�����÷�ʹ��
	mov ah,g_deleteStartIndex
	mov al,g_deleteEndIndex
    ret 
DeleteRange endp

ReadCh_M4  PROC           ;ֻ��ȡһ���ֽ�

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

ReadCh_M4 ENDP 

ShowCh_M4 PROC 
    inc g_currentIndex      ;ÿ��ȡһ���ֽ�,��ǰ��ȡλ��������һ���ֽ�
    inc g_deleteEndIndex    ;ÿ��ȡһ���ֽ�,Ҫɾ�����ļ�����λ��������һ���ֽ�

    ;�ж��ļ������ȡ�ĵ�ǰ�ַ��Ƿ�Ϊ $
	cmp al,'$'
	jz IsDoller
	cmp al,'*'
	jz IsStar
	jnz NormalCh
	
NormalCh:
    cmp g_isAllowSet_deleteStartIndex,1    ;����ļ���һ��ʼ���� ******* ,��ô,�ǲ���������ʼλ�õ�
	mov bx,offset g_currentIndex
	xor ax,ax
	mov al,byte ptr ds:[bx]
	mov bx,offset g_deleteStartIndex
	mov byte ptr ds:[bx],al    ;����ǰλ�ø�ֵ��Ҫɾ������ʼλ��
	sub g_isAllowSet_deleteStartIndex,1      ;���ò������ g_deleteStartIndex(Ҫɾ������ʼλ��) ��ֵ 
	ret

IsStar:  ;��ȡ������ * 
    ;λ�õ�++�Ѿ������������
    ret
	
IsDoller:
    ;����һ����¼�Ľ�β,�������� g_deleteStartIndex(Ҫɾ������ʼλ��) ����ֵ
	add g_isAllowSet_deleteStartIndex,1
	
	mov bx,offset g_currentDollarIndex
	xor ax,ax
	mov al,byte ptr ds:[bx]
	mov bx,offset g_deleteIndex
	xor cx,cx
	mov cl,byte ptr ds:[bx]
    cmp ax,cx
	jz findDeleteIndex
	jnz continueFindDeleteIndex
	
continueFindDeleteIndex:
    inc g_currentDollarIndex    ;��ǰ�ڲ��ҵ�$�±�λ��++
    ret
findDeleteIndex:
	inc g_finish
    ret
ShowCh_M4 ENDP
    
MyCode9 ends

end











































