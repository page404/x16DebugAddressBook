
MyData segment
    g_FileName  db 'StuData.txt$'
	g_Buffer DB 100 DUP (?)
	g_HAND DW ?                     ;文件代号
	g_Offset DW 00H                 ;偏移量
    g_strEnter  db 0dh, 0ah, '$'    ;回车 换行 
	g_WriteFail   db 0
	BUFFER DB ?                     ;1字节的缓冲区
	
    g_WriteToFileInfo  db 'writing to file...$'
	
	g_callSegOffset dw 00h   ;调用该函数所在段传过来的字符串在该段的段偏移
	g_DataLength db 0       ;实际要写入文本的数据长度
	g_index db 0
	g_delete db 0h
    
MyData ends


MyCode10 segment

DeleteStudent proc far ;near
    ;数据段给类型 或者说是 声明数据段
    assume  cs:MyCode10, ds:MyData
    ;进堆栈的顺序依次是  参数ax->后面几个是系统自己保存到堆栈里面的->cs->ip->bp->local->regs
    argHexAsc_ax = word ptr 6       ;全局变量写法
	argHexAsc_ds = word ptr 8       ;全局变量写法
    @wRetVal = word ptr -2       ;局部变量写法
    push bp       ;保存之前的bp,因为bp会被覆盖
    mov bp, sp    ;栈顶给栈底,保存栈
    sub sp, 2     ;sp = sp -2 保存环境用的栈顶往后移2个字节,空出来的这两个字节用来存放返回值
    
	;保存环境
    push ds
    push dx
    push di
    push bx
	push si
	push sp
	push cx
	push es
    
    ;---------设置数据段
    mov ax, MyData
    mov ds, ax
    
	;如果 [bp+@wRetVal] 值最后为0:当前处理的16进制字符非法    如果 [bp+@wRetVal] 值最后为 1:当前处理的16进制字节合法
    mov [bp+@wRetVal], 0
	
	
	;----------打开指定的文件
	;文件打开成功:AX=文件代号
	;文件打开错误:AX=错误码
	mov dx,offset g_FileName
	mov al,3      ;AL= 0:读  1:写 3:读/写
	mov ah,3dh    ;21h中的 序号3d中断
	int 21h
	JC ERROR        ;出错跳转
    ;执行到这里后,文件代号将在AX里
    MOV g_HAND,AX     ;文件代号存进HAND里

ReadChLoop:
    call WriteToFile_M2    ;写入文件
	JC ERROR        ;出错跳转
	jmp NormalFinish       ;是，转
	
	
ERROR:    ;直接结束

    MOV AH,4CH       ; 带返回码结束    AX=返回代码
    INT 21H
	
NormalFinish:

	;---------关闭文件
	;失败:AX=错误码 
	MOV BX,g_HAND         ;BX为要读取的文件代号  
	MOV AH,3EH        ;关闭文件
    INT 21H
	

	;将是否合法的值给ax寄存器，被调方就可以在出函数的时候直接使用ax即可。
    mov ax, [bp+@wRetVal]    
    
    ;ax在这里用来在函数间传参数,不能push pop
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
    
    ret 4      ;在执行ret指令的基础上sp再加4. 用来平栈,因为调用该函数的地方有一个 push ds push ax 操作.
DeleteStudent endp

WriteToFile_M2  PROC           ;向文件写入数据

        ;写入文件的字符串首地址
        mov es, [bp+argHexAsc_ds]       ;[bp+argHexAsc_ds] 得到的是传入的参数
        mov ax, [bp+argHexAsc_ax]       ;[bp+argHexAsc_ax] 得到的是传入的参数
		mov bx,offset g_callSegOffset
		mov word ptr ds:[bx],ax
        mov bx,ax
		
	    ;------计算要写入的字节数,数据中最后的$也要写入文本
		xor cx,cx
    dataLength:
		mov si,cx
		add cx,1
		cmp byte ptr es:[bx+si],'$'    
		jnz dataLength    ;----- 循环调用
		
		;将要写入文本的数据长度值存放到 g_DataLength
		mov bx,offset g_DataLength
		mov byte ptr ds:[bx],cl

		
		;将参数传入过来的数据段里的数据复制到本文件的数据段,如果不复制过来,写入不到文本里面
moveData:
        ;调用方所在段的字符串当中的一个字符
		
		;得到 g_index 的值
		mov bx,offset g_index
		xor cx,cx
		mov cl,byte ptr ds:[bx]
		
		;得到传过来的数据段的其中一个字节
		mov bx,offset g_callSegOffset
		mov ax,word ptr ds:[bx]
		mov bx,ax
		add bx,cx
		mov al,byte ptr es:[bx]
		
		;将调用方所在段的字符串中的字符赋值到该函数的段中 (不复制过来,写入不到文本里面)
		mov bx,offset g_Buffer
		add bx,cx
		mov byte ptr ds:[bx],al
		
		inc g_index
		
		;判断当前复制到了哪个位置
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
		
		
		
		;-------移动文件指针
		MOV CX,0    ;CX:DX是偏移量
		MOV DX,0     
		MOV AL,2        ;移动方式:0:从文件头绝对位移  1:从当前位置相对移动  2:从文件尾绝对位移 
		MOV BX,g_HAND     ;文件代号给BX
		MOV AH,42H      ;移动文件指针
		INT 21H
        
		;--------写入数据到文件   
		;DS:DX=数据缓冲区地址     
		;BX=文件代号     
		;CX=要写入的字节数
		;写成功:
		    ;AX=实际写入的字节数
			;写出错:AX=错误码
			
        mov bx,offset g_DataLength
		xor ax,ax
		mov al,byte ptr ds:[bx]
        ;不同的数据段，不能写入到文本里面，只会打印在屏幕上。
		;mov DX,di   ;DS:DX=数据缓冲区地址 , 因为是在不同的数据段,所以上面已经手动设置了要取数据的 ds 段(从调用方传过来的)
		mov dx,offset g_Buffer
		MOV BX,g_HAND         ;BX为要读取的文件代号
		MOV CX,ax       ;CX为要写入的字节数
		MOV AH,40h        ;------40h写入数据到文件
		INT 21H
		
		
		JC ReadChError        ;错误跳转
		mov [bp+@wRetVal], 1

	ReadChEnd:
	    CLC     ;清除CF位 
	ReadChError:
	    RET 
WriteToFile_M2 ENDP 
    
MyCode10 ends

end





















