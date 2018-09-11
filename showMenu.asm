
MyData segment
    g_FileName  db 'Menu.txt',00H
	g_Buffer DB 100 DUP (?)
	g_HAND DW ?                     ;文件代号
	g_Offset DW 00H                 ;偏移量
    g_strEnter  db 0dh, 0ah, '$'    ;回车 换行 
	g_FileEnd   db 0
	BUFFER DB ?                     ;1字节的缓冲区
	
MyData ends

MyCode3 segment

ShowMenu proc far ;near
    ;数据段给类型 或者说是 声明数据段
    assume  cs:MyCode3, ds:MyData

    ;---------设置数据段
    mov ax, MyData
    mov ds, ax

    ;----------打开指定的文件
	;文件打开成功:AX=文件代号
	;文件打开错误:AX=错误码
	mov dx,offset g_FileName
	mov al,0      ;AL= 0:读  1:写 3:读/写
	mov ah,3dh    ;21h中的 序号3d中断
	int 21h
	JC ERROR        ;出错跳转
    ;执行到这里后,文件代号将在AX里
    MOV g_HAND,AX     ;文件代号存进HAND里

ReadChLoop:
    call ReadCh    ;每次只读取一个字节
	JC ERROR        ;出错跳转
	CMP AL,g_FileEnd     ;读到文件结束符吗？
	JZ NormalFinish       ;是，转
	call ShowCh
	JMP ReadChLoop       ;--------------------------循环读取
	
	
ERROR:    ;直接结束
    MOV AH,4CH       ; 带返回码结束    AX=返回代码
    INT 21H
	
NormalFinish:
	;---------关闭文件
	;失败:AX=错误码 
	MOV BX,g_HAND         ;BX为要读取的文件代号  
	MOV AH,3EH        ;关闭文件
    INT 21H
	
	;回车 换行 
    ; mov dx, offset g_strEnter
    ; mov ah, 09h
    ; int 21h
	
	;------------清空当前的标准输入缓冲区
	;出口参数：若入口参数AL为0AH，则DS:DX＝存放输入字符的起始地
	; mov al,0ah
	; MOV AH,0ch
	; INT 21H

    ret 
ShowMenu endp

ReadCh  PROC           ;只读取一个字节

		;--------读取文件内容
		;读成功:   
			;AX=实际读入的字节数    
			;AX=0 表示已到文件尾  
		;读出错:
			;AX=错误码 
		mov DX,offset BUFFER   ;g_Buffer 存放读取到的数据
		MOV BX,g_HAND         ;BX为要读取的文件代号
		MOV CX,1        ;CX为读取的字节数
		MOV AH,3fh        ;3fh 读取文件或设备
		INT 21H
		JC ReadChError        ;错误跳转
		
		CMP AX,CX          ;判文件是否结束 
		MOV AL,g_FileEnd     ;假设文件已经结束,置文件结束符 
		JB ReadChEnd         ;文件确已结束，转   ax 小于 cx
		MOV AL,BUFFER      ;文件未结束，取所读字

	ReadChEnd:CLC     ;清除CF位 
	ReadChError:RET 

ReadCh ENDP 

ShowCh PROC 
    PUSH DX 
    MOV DL,AL       ;DL存放要输出的字符
    MOV AH,2        ;显示输出	DL=输出字符 
    INT 21H 
    POP DX 
    RET
ShowCh ENDP
    
MyCode3 ends

end





















