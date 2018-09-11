
MyData segment
    g_FileName  db 'StuData.txt',00H
	g_HAND DW ?                     ;�ļ�����
	g_Offset DW 00H                 ;ƫ����
	g_FileEnd   db 0
	BUFFER DB ?                     ;1�ֽڵĻ�����
	;�س� ���� 
    g_strEnter  db 0dh, 0ah, '$'
	
	;------Ҫ���ҵ��ַ���
	;Ҫ���ҵ��ַ����ܳ��� , $ �ĳ���Ҳ����������
	g_SearchStr_TotalLength db 0       
	;Ҫ�����ַ�����ǰƥ�䵽���ĸ�λ�� 
	g_SearchStrCurrentPosition db 0
	
	;-----�ļ��е�����
	;�ļ��е�����¼�Ļ���
	g_SearchResult_OneRecord_Buffer DB 100 DUP (0)    
	;�ļ��е�����¼���±�λ��  , $ �ĳ���Ҳ����������
	g_SearchResultCurrentPosition_OneRecord db 0
	
	g_callSegOffset dw 00h   ;���øú������ڶδ��������ַ����ڸöεĶ�ƫ��
	
	g_closeFileTip db 'close file finish!$'
	g_closeFileErrorTip db 'close file error!$'
	
	g_x db 0
	g_y db 0
	g_n db 0
	g_m db 0
MyData ends


MyCode7 segment

SearchFile proc far ;near
    ;���ݶθ����� ����˵�� �������ݶ�
    assume  cs:MyCode7, ds:MyData
	
	;����ջ��˳��������  ����ax->���漸����ϵͳ�Լ����浽��ջ�����->cs->ip->bp->local->regs
    argHexAsc_ax = word ptr 6       ;ȫ�ֱ���д��
	argHexAsc_ds = word ptr 8       ;ȫ�ֱ���д��
    @wRetVal = word ptr -2       ;�ֲ�����д��
    push bp       ;����֮ǰ��bp,��Ϊbp�ᱻ����
    mov bp, sp    ;ջ����ջ��,����ջ
    sub sp, 2     ;sp = sp -2 ���滷���õ�ջ��������2���ֽ�,�ճ������������ֽ�������ŷ���ֵ
    
	;���滷��
    push ds
    push dx
    push di
    push bx
	push si
	push sp
	push cx

    ;---------�������ݶ�
    mov ax, MyData
    mov ds, ax
	
	;��� [bp+@wRetVal] ֵ���Ϊ0:��ǰ�����16�����ַ��Ƿ�    ��� [bp+@wRetVal] ֵ���Ϊ 1:��ǰ�����16�����ֽںϷ�
    mov [bp+@wRetVal], 0

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
    call ReadCh_M3    ;ÿ��ֻ��ȡһ���ֽ�
	JC ERROR        ;������ת
	CMP AL,g_FileEnd     ;�����ļ���������
	JZ NormalFinish       ;�ر��ļ�����,���غ���
	call MatchingString   ;����ı��ж�ȡ���� $ , �ڸ� proc ��һ���Դ���
	JMP ReadChLoop       ;--------------------------ѭ����ȡ
	
	
ERROR:    ;ֱ�ӽ���

    ;�س� ���� 
	mov dx,offset g_strEnter
    mov ah, 09h
    int 21h
    
	;-----------�������е��ַ����������Ļ��
	;��ʾ�ַ���  DS:DX����ַ  $�����ַ���
	mov dx,offset g_closeFileErrorTip
	mov ah,09h
	int 21h

    MOV AH,4CH       ; �����������    AX=���ش���
    INT 21H
	
NormalFinish:

    ;�س� ���� 
	mov dx,offset g_strEnter
    mov ah, 09h
    int 21h

    ;-----------�������е��ַ����������Ļ��
	;��ʾ�ַ���  DS:DX����ַ  $�����ַ���
	mov dx,offset g_closeFileTip
	mov ah,09h
	int 21h

	;---------�ر��ļ�
	;ʧ��:AX=������ 
	MOV BX,g_HAND         ;BXΪҪ��ȡ���ļ�����  
	MOV AH,3EH        ;�ر��ļ�
    INT 21H
	
	;�س� ���� 
    mov dx, offset g_strEnter
    mov ah, 09h
    int 21h
	
    ;���Ƿ�Ϸ���ֵ��ax�Ĵ������������Ϳ����ڳ�������ʱ��ֱ��ʹ��ax���ɡ�
    mov ax, [bp+@wRetVal]    
	
	;ax�����������ں����䴫����,����push pop
	pop cx
	pop sp
	pop si
    pop bx
    pop di
    pop dx
    pop ds
    
    mov sp, bp
    pop bp
    
    ret 4      ;��ִ��retָ��Ļ�����sp�ټ�4. ����ƽջ,��Ϊ���øú����ĵط���һ�� push ds push ax ����.
SearchFile endp

ReadCh_M3  PROC           ;ֻ��ȡһ���ֽ�

		;--------��ȡ�ļ�����
		;���ɹ�:   
			;AX=ʵ�ʶ�����ֽ���    
			;AX=0 ��ʾ�ѵ��ļ�β  
		;������:
			;AX=������ 
		mov DX,offset BUFFER   ;BUFFER ��Ŷ�ȡ��������
		MOV BX,g_HAND         ;BXΪҪ��ȡ���ļ�����
		MOV CX,1        ;CXΪ��ȡ���ֽ���
		MOV AH,3fh        ;3fh ��ȡ�ļ����豸
		INT 21H
		JC ReadChError        ;������ת
		
		CMP AX,CX          ;���ļ��Ƿ���� 
		MOV AL,g_FileEnd     ;�����ļ��Ѿ�����,���ļ������� 
		JB ReadChEnd         ;�ļ�ȷ�ѽ�����ת   ax С�� cx
		mov bx,offset BUFFER
		MOV AL,byte ptr ds:[bx]      ;�ļ�δ������ȡ������

	ReadChEnd:CLC     ;���CFλ 
	ReadChError:RET 

ReadCh_M3 ENDP 

;ƥ���ַ���    ����ı��ж�ȡ���� $ , �ڸ� proc ��һ���Դ���
MatchingString PROC 
    ;al Ϊ�ļ������ȡ���ĵ�ǰ�ַ�����
	
	;�ж��Ƿ���ļ���ȡ����һ�������ļ�¼
    cmp al,'$'
	jz readRecordFromTxtComplete  
	jnz unReadRecordFinish
	
readRecordFromTxtComplete:  ;�Ѿ����ļ���ȡ����һ�������ļ�¼
	
	;�������ַ����������� $ 
	mov bx,offset g_SearchResultCurrentPosition_OneRecord  ;g_SearchResultCurrentPosition_OneRecord ��ֵΪ�ļ���һ����¼�ĳ���
	xor ax,ax
	mov al,byte ptr ds:[bx]
	mov si,offset g_SearchResult_OneRecord_Buffer
	add si,ax
    mov byte ptr ds:[si],'$' 
    inc g_SearchResultCurrentPosition_OneRecord
	
	;-----�õ�Ҫ�����ַ������׵�ַ
    mov es, [bp+argHexAsc_ds]       ;[bp+argHexAsc_ds] �õ����Ǵ���Ĳ���
    mov ax, [bp+argHexAsc_ax]       ;[bp+argHexAsc_ax] �õ����Ǵ���Ĳ���
	mov bx,offset g_callSegOffset
	mov word ptr ds:[bx],ax
	mov bx,ax
	
;-----����Ҫ�����ַ������ܳ���(����ĳ��Ȱ�����$)
searchStrTotalLengthLoop:
    xor ax,ax
	mov al,g_SearchStr_TotalLength
    mov si,ax 
	add g_SearchStr_TotalLength,1    ;����ŵ� cmp ����,��ı��־λ,Ӱ�쵽 jnz
    cmp byte ptr es:[bx+si],'$'  
	jnz searchStrTotalLengthLoop
	
;-----------------------------�ж�Ҫ���ҵ��ַ����Ƿ������������ݴ���ƥ��
ResetMatchStringLoop:
    ;����: g_x = g_y    ������ �����е��ַ���
	mov si,offset g_y
	mov al,byte ptr ds:[si]
	mov si,offset g_x
    mov byte ptr [si],al
	
		
	;����: g_n = g_m    �ڲ���� Ҫ���ҵ��ַ���
	mov si,offset g_m
	xor bx,bx
	mov bl,byte ptr ds:[si]
	mov si,offset g_n
    mov byte ptr [si],bl 

MatchStringLoop: 
    
	;----�õ������е�һ���ֽ�
	mov bx,offset g_x
	xor ax,ax
	mov al,byte ptr ds:[bx]
	mov si,offset g_SearchResult_OneRecord_Buffer
	add si,ax
	xor ax,ax
	mov al,byte ptr ds:[si]    ;alΪ �õ������е�һ���ֽ�
	inc g_x
	
	;----�õ�Ҫ�����ַ����е�һ���ֽ�
	xor cx,cx
	mov bx,offset g_n
	mov cl,byte ptr ds:[bx]    ;cxΪg_n��ֵ
	mov bx,offset g_callSegOffset
	mov dx,word ptr ds:[bx]    ;dxΪ g_callSegOffset ��ֵ
	add dx,cx
	mov bx,dx
	xor dx,dx
	mov dl,byte ptr es:[bx]    ;dl Ϊ Ҫ�����ַ����е�һ���ֽ�    
	inc g_n
	
	;�ж��Ƿ�Ϊ��һһ���ַ����Ľ��� , ------ ����ѭ��
	cmp dl,'$'    ;ƥ��ɹ�
	jz N_M_Finish
	cmp al,'$'    ;�����е�����¼ƥ�䲻�ɹ�
	jz X_Y_Finish
	
	
	cmp ax,dx
	jz MatchStringLoop    ;��ǰ���ֽ�ƥ��
	jnz ResetPosition     ;��ǰ���ֽڲ�ƥ��
	
ResetPosition:
    ;��ǰ�Ƚϵ��ֽڲ�ƥ��,��λ
    inc g_y
	mov g_m,0
	jmp ResetMatchStringLoop
	
unReadRecordFinish:  ;һ�������ļ�¼��δ��ȡ���
    mov bx,offset g_SearchResultCurrentPosition_OneRecord
	xor cx,cx
    mov cl,byte ptr ds:[bx]
	mov si,offset g_SearchResult_OneRecord_Buffer
	add si,cx
	mov byte ptr ds:[si],al    ;alΪ���ļ��ж�ȡ��������һ���ַ�
	inc g_SearchResultCurrentPosition_OneRecord
	jmp NormalChProcFinish
	
X_Y_Finish:  ;����ת���˴�,˵�������ַ�����ƥ��Ҫ���ҵ��ַ���,����,�ٴ��ļ��ж�ȡһ����¼
    jmp NormalRecordProcFinish
	
N_M_Finish:    ;���Ƚϵ���Ҫ�����ַ�����$λ��,˵��ģ��ƥ��ɹ�,��ת�� matchStringSuccess
    jmp matchStringSuccess  
	
matchStringSuccess:    ;�ַ���ƥ��ɹ� , ��ӡ�������Ļ

    mov [bp+@wRetVal], 1
	
	;�س� ���� 
	mov dx,offset g_strEnter
    mov ah, 09h
    int 21h

    ;-----------�������е��ַ����������Ļ��
	;��ʾ�ַ���  DS:DX����ַ  $�����ַ���
	mov dx,offset g_SearchResult_OneRecord_Buffer
	mov ah,09h
	int 21h
	
	jmp NormalRecordProcFinish

matchStringFail:
    jmp NormalRecordProcFinish
	
NormalChProcFinish:
	ret
	
NormalRecordProcFinish:

    xor bx,bx
resetData:  ;���Ҫ���ô˹���,����� NormalRecordProcFinish
    ;-----�������ַ�����صı�����λ,����һ���ļ���¼ʹ��
	mov si,offset g_SearchResult_OneRecord_Buffer
    mov byte ptr ds:[si+bx],0 
	inc bl
	cmp bl,g_SearchResultCurrentPosition_OneRecord
	jnz resetData
	mov g_SearchResultCurrentPosition_OneRecord,0
	
	mov g_SearchStr_TotalLength,0
	mov g_SearchStrCurrentPosition,0
	mov g_x,0
	mov g_y,0
	mov g_n,0
	mov g_m,0
	
	ret
MatchingString ENDP
    
MyCode7 ends

end











































