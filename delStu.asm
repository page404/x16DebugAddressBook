
MyData segment
    g_FileName  db 'StuData.txt$'
	g_Buffer DB 100 DUP (?)
	g_HAND DW ?                     ;�ļ�����
	g_Offset DW 00H                 ;ƫ����
    g_strEnter  db 0dh, 0ah, '$'    ;�س� ���� 
	g_WriteFail   db 0
	BUFFER DB ?                     ;1�ֽڵĻ�����
	
    g_WriteToFileInfo  db 'writing to file...$'
	
	g_callSegOffset dw 00h   ;���øú������ڶδ��������ַ����ڸöεĶ�ƫ��
	g_DataLength db 0       ;ʵ��Ҫд���ı������ݳ���
	g_index db 0
	g_delete db 0h
    
MyData ends


MyCode10 segment

DeleteStudent proc far ;near
    ;���ݶθ����� ����˵�� �������ݶ�
    assume  cs:MyCode10, ds:MyData
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
	push es
    
    ;---------�������ݶ�
    mov ax, MyData
    mov ds, ax
    
	;��� [bp+@wRetVal] ֵ���Ϊ0:��ǰ�����16�����ַ��Ƿ�    ��� [bp+@wRetVal] ֵ���Ϊ 1:��ǰ�����16�����ֽںϷ�
    mov [bp+@wRetVal], 0
	
	
	;----------��ָ�����ļ�
	;�ļ��򿪳ɹ�:AX=�ļ�����
	;�ļ��򿪴���:AX=������
	mov dx,offset g_FileName
	mov al,3      ;AL= 0:��  1:д 3:��/д
	mov ah,3dh    ;21h�е� ���3d�ж�
	int 21h
	JC ERROR        ;������ת
    ;ִ�е������,�ļ����Ž���AX��
    MOV g_HAND,AX     ;�ļ����Ŵ��HAND��

ReadChLoop:
    call WriteToFile_M2    ;д���ļ�
	JC ERROR        ;������ת
	jmp NormalFinish       ;�ǣ�ת
	
	
ERROR:    ;ֱ�ӽ���

    MOV AH,4CH       ; �����������    AX=���ش���
    INT 21H
	
NormalFinish:

	;---------�ر��ļ�
	;ʧ��:AX=������ 
	MOV BX,g_HAND         ;BXΪҪ��ȡ���ļ�����  
	MOV AH,3EH        ;�ر��ļ�
    INT 21H
	

	;���Ƿ�Ϸ���ֵ��ax�Ĵ������������Ϳ����ڳ�������ʱ��ֱ��ʹ��ax���ɡ�
    mov ax, [bp+@wRetVal]    
    
    ;ax�����������ں����䴫����,����push pop
	pop es
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
DeleteStudent endp

WriteToFile_M2  PROC           ;���ļ�д������

        ;д���ļ����ַ����׵�ַ
        mov es, [bp+argHexAsc_ds]       ;[bp+argHexAsc_ds] �õ����Ǵ���Ĳ���
        mov ax, [bp+argHexAsc_ax]       ;[bp+argHexAsc_ax] �õ����Ǵ���Ĳ���
		mov bx,offset g_callSegOffset
		mov word ptr ds:[bx],ax
        mov bx,ax
		
	    ;------����Ҫд����ֽ���,����������$ҲҪд���ı�
		xor cx,cx
    dataLength:
		mov si,cx
		add cx,1
		cmp byte ptr es:[bx+si],'$'    
		jnz dataLength    ;----- ѭ������
		
		;��Ҫд���ı������ݳ���ֵ��ŵ� g_DataLength
		mov bx,offset g_DataLength
		mov byte ptr ds:[bx],cl

		
		;������������������ݶ�������ݸ��Ƶ����ļ������ݶ�,��������ƹ���,д�벻���ı�����
moveData:
        ;���÷����ڶε��ַ������е�һ���ַ�
		
		;�õ� g_index ��ֵ
		mov bx,offset g_index
		xor cx,cx
		mov cl,byte ptr ds:[bx]
		
		;�õ������������ݶε�����һ���ֽ�
		mov bx,offset g_callSegOffset
		mov ax,word ptr ds:[bx]
		mov bx,ax
		add bx,cx
		mov al,byte ptr es:[bx]
		
		;�����÷����ڶε��ַ����е��ַ���ֵ���ú����Ķ��� (�����ƹ���,д�벻���ı�����)
		mov bx,offset g_Buffer
		add bx,cx
		mov byte ptr ds:[bx],al
		
		inc g_index
		
		;�жϵ�ǰ���Ƶ����ĸ�λ��
		xor ax,ax
		mov bx,offset g_DataLength
		mov al,byte ptr ds:[bx]
		xor cx,cx
		mov bx,offset g_index
		mov cl,byte ptr ds:[bx]
		cmp ax,cx
		
		jnz moveData
		
		mov bx,offset g_Buffer
		mov byte ptr ds:[bx + g_index],'$'
		
		
		
		;-------�ƶ��ļ�ָ��
		MOV CX,0    ;CX:DX��ƫ����
		MOV DX,0     
		MOV AL,2        ;�ƶ���ʽ:0:���ļ�ͷ����λ��  1:�ӵ�ǰλ������ƶ�  2:���ļ�β����λ�� 
		MOV BX,g_HAND     ;�ļ����Ÿ�BX
		MOV AH,42H      ;�ƶ��ļ�ָ��
		INT 21H
        
		;--------д�����ݵ��ļ�   
		;DS:DX=���ݻ�������ַ     
		;BX=�ļ�����     
		;CX=Ҫд����ֽ���
		;д�ɹ�:
		    ;AX=ʵ��д����ֽ���
			;д����:AX=������
			
        mov bx,offset g_DataLength
		xor ax,ax
		mov al,byte ptr ds:[bx]
        ;��ͬ�����ݶΣ�����д�뵽�ı����棬ֻ���ӡ����Ļ�ϡ�
		;mov DX,di   ;DS:DX=���ݻ�������ַ , ��Ϊ���ڲ�ͬ�����ݶ�,���������Ѿ��ֶ�������Ҫȡ���ݵ� ds ��(�ӵ��÷���������)
		mov dx,offset g_Buffer
		MOV BX,g_HAND         ;BXΪҪ��ȡ���ļ�����
		MOV CX,ax       ;CXΪҪд����ֽ���
		MOV AH,40h        ;------40hд�����ݵ��ļ�
		INT 21H
		
		
		JC ReadChError        ;������ת
		mov [bp+@wRetVal], 1

	ReadChEnd:
	    CLC     ;���CFλ 
	ReadChError:
	    RET 
WriteToFile_M2 ENDP 
    
MyCode10 ends

end





















