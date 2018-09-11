
MyData segment
    g_FileName  db 'StuData.txt',00H
	g_HAND DW ?                     ;文件代号
	g_Offset DW 00H                 ;偏移量
	g_FileEnd   db 0
	BUFFER DB ?                     ;1字节的缓冲区
	;回车 换行 
    g_strEnter  db 0dh, 0ah, '$'
	
	;------要查找的字符串
	;要查找的字符串总长度 , $ 的长度也计算在内了
	g_SearchStr_TotalLength db 0       
	;要查找字符串当前匹配到了哪个位置 
	g_SearchStrCurrentPosition db 0
	
	;-----文件中的数据
	;文件中单条记录的缓存
	g_SearchResult_OneRecord_Buffer DB 100 DUP (0)    
	;文件中单条记录的下标位置  , $ 的长度也计算在内了
	g_SearchResultCurrentPosition_OneRecord db 0
	
	g_callSegOffset dw 00h   ;调用该函数所在段传过来的字符串在该段的段偏移
	
	g_closeFileTip db 'close file finish!$'
	g_closeFileErrorTip db 'close file error!$'
	
	g_x db 0
	g_y db 0
	g_n db 0
	g_m db 0
MyData ends


MyCode7 segment

SearchFile proc far ;near
    ;数据段给类型 或者说是 声明数据段
    assume  cs:MyCode7, ds:MyData
	
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

    ;---------设置数据段
    mov ax, MyData
    mov ds, ax
	
	;如果 [bp+@wRetVal] 值最后为0:当前处理的16进制字符非法    如果 [bp+@wRetVal] 值最后为 1:当前处理的16进制字节合法
    mov [bp+@wRetVal], 0

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
    call ReadCh_M3    ;每次只读取一个字节
	JC ERROR        ;出错跳转
	CMP AL,g_FileEnd     ;读到文件结束符吗？
	JZ NormalFinish       ;关闭文件操作,返回函数
	call MatchingString   ;如果文本中读取到了 $ , 在该 proc 里一次性处理
	JMP ReadChLoop       ;--------------------------循环读取
	
	
ERROR:    ;直接结束

    ;回车 换行 
	mov dx,offset g_strEnter
    mov ah, 09h
    int 21h
    
	;-----------将缓存中的字符串输出到屏幕上
	;显示字符串  DS:DX串地址  $结束字符串
	mov dx,offset g_closeFileErrorTip
	mov ah,09h
	int 21h

    MOV AH,4CH       ; 带返回码结束    AX=返回代码
    INT 21H
	
NormalFinish:

    ;回车 换行 
	mov dx,offset g_strEnter
    mov ah, 09h
    int 21h

    ;-----------将缓存中的字符串输出到屏幕上
	;显示字符串  DS:DX串地址  $结束字符串
	mov dx,offset g_closeFileTip
	mov ah,09h
	int 21h

	;---------关闭文件
	;失败:AX=错误码 
	MOV BX,g_HAND         ;BX为要读取的文件代号  
	MOV AH,3EH        ;关闭文件
    INT 21H
	
	;回车 换行 
    mov dx, offset g_strEnter
    mov ah, 09h
    int 21h
	
    ;将是否合法的值给ax寄存器，被调方就可以在出函数的时候直接使用ax即可。
    mov ax, [bp+@wRetVal]    
	
	;ax在这里用来在函数间传参数,不能push pop
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
SearchFile endp

ReadCh_M3  PROC           ;只读取一个字节

		;--------读取文件内容
		;读成功:   
			;AX=实际读入的字节数    
			;AX=0 表示已到文件尾  
		;读出错:
			;AX=错误码 
		mov DX,offset BUFFER   ;BUFFER 存放读取到的数据
		MOV BX,g_HAND         ;BX为要读取的文件代号
		MOV CX,1        ;CX为读取的字节数
		MOV AH,3fh        ;3fh 读取文件或设备
		INT 21H
		JC ReadChError        ;错误跳转
		
		CMP AX,CX          ;判文件是否结束 
		MOV AL,g_FileEnd     ;假设文件已经结束,置文件结束符 
		JB ReadChEnd         ;文件确已结束，转   ax 小于 cx
		mov bx,offset BUFFER
		MOV AL,byte ptr ds:[bx]      ;文件未结束，取所读字

	ReadChEnd:CLC     ;清除CF位 
	ReadChError:RET 

ReadCh_M3 ENDP 

;匹配字符串    如果文本中读取到了 $ , 在该 proc 里一次性处理
MatchingString PROC 
    ;al 为文件里面读取到的当前字符数据
	
	;判断是否从文件里取出了一条完整的记录
    cmp al,'$'
	jz readRecordFromTxtComplete  
	jnz unReadRecordFinish
	
readRecordFromTxtComplete:  ;已经从文件读取出了一条完整的记录
	
	;给缓存字符串最后面加上 $ 
	mov bx,offset g_SearchResultCurrentPosition_OneRecord  ;g_SearchResultCurrentPosition_OneRecord 的值为文件中一条记录的长度
	xor ax,ax
	mov al,byte ptr ds:[bx]
	mov si,offset g_SearchResult_OneRecord_Buffer
	add si,ax
    mov byte ptr ds:[si],'$' 
    inc g_SearchResultCurrentPosition_OneRecord
	
	;-----得到要查找字符串的首地址
    mov es, [bp+argHexAsc_ds]       ;[bp+argHexAsc_ds] 得到的是传入的参数
    mov ax, [bp+argHexAsc_ax]       ;[bp+argHexAsc_ax] 得到的是传入的参数
	mov bx,offset g_callSegOffset
	mov word ptr ds:[bx],ax
	mov bx,ax
	
;-----计算要查找字符串的总长度(计算的长度包括了$)
searchStrTotalLengthLoop:
    xor ax,ax
	mov al,g_SearchStr_TotalLength
    mov si,ax 
	add g_SearchStr_TotalLength,1    ;如果放到 cmp 下面,会改变标志位,影响到 jnz
    cmp byte ptr es:[bx+si],'$'  
	jnz searchStrTotalLengthLoop
	
;-----------------------------判断要查找的字符串是否跟缓存里的数据存在匹配
ResetMatchStringLoop:
    ;功能: g_x = g_y    外层遍历 缓存中的字符串
	mov si,offset g_y
	mov al,byte ptr ds:[si]
	mov si,offset g_x
    mov byte ptr [si],al
	
		
	;功能: g_n = g_m    内层遍历 要查找的字符串
	mov si,offset g_m
	xor bx,bx
	mov bl,byte ptr ds:[si]
	mov si,offset g_n
    mov byte ptr [si],bl 

MatchStringLoop: 
    
	;----得到缓存中的一个字节
	mov bx,offset g_x
	xor ax,ax
	mov al,byte ptr ds:[bx]
	mov si,offset g_SearchResult_OneRecord_Buffer
	add si,ax
	xor ax,ax
	mov al,byte ptr ds:[si]    ;al为 得到缓存中的一个字节
	inc g_x
	
	;----得到要查找字符串中的一个字节
	xor cx,cx
	mov bx,offset g_n
	mov cl,byte ptr ds:[bx]    ;cx为g_n的值
	mov bx,offset g_callSegOffset
	mov dx,word ptr ds:[bx]    ;dx为 g_callSegOffset 的值
	add dx,cx
	mov bx,dx
	xor dx,dx
	mov dl,byte ptr es:[bx]    ;dl 为 要查找字符串中的一个字节    
	inc g_n
	
	;判断是否为任一一个字符串的结束 , ------ 跳出循环
	cmp dl,'$'    ;匹配成功
	jz N_M_Finish
	cmp al,'$'    ;缓存中当条记录匹配不成功
	jz X_Y_Finish
	
	
	cmp ax,dx
	jz MatchStringLoop    ;当前的字节匹配
	jnz ResetPosition     ;当前的字节不匹配
	
ResetPosition:
    ;当前比较的字节不匹配,复位
    inc g_y
	mov g_m,0
	jmp ResetMatchStringLoop
	
unReadRecordFinish:  ;一条完整的记录还未读取完成
    mov bx,offset g_SearchResultCurrentPosition_OneRecord
	xor cx,cx
    mov cl,byte ptr ds:[bx]
	mov si,offset g_SearchResult_OneRecord_Buffer
	add si,cx
	mov byte ptr ds:[si],al    ;al为从文件中读取到的其中一个字符
	inc g_SearchResultCurrentPosition_OneRecord
	jmp NormalChProcFinish
	
X_Y_Finish:  ;当跳转到此处,说明缓存字符串不匹配要查找的字符串,重置,再从文件中读取一条记录
    jmp NormalRecordProcFinish
	
N_M_Finish:    ;当比较到了要查找字符串的$位置,说明模糊匹配成功,跳转到 matchStringSuccess
    jmp matchStringSuccess  
	
matchStringSuccess:    ;字符串匹配成功 , 打印输出到屏幕

    mov [bp+@wRetVal], 1
	
	;回车 换行 
	mov dx,offset g_strEnter
    mov ah, 09h
    int 21h

    ;-----------将缓存中的字符串输出到屏幕上
	;显示字符串  DS:DX串地址  $结束字符串
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
resetData:  ;如果要调用此功能,请调用 NormalRecordProcFinish
    ;-----将缓存字符串相关的变量复位,给下一条文件记录使用
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











































