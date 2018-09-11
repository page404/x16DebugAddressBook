
MyData segment
    g_FileName  db 'StuData.txt',00H
	g_Buffer DB 100 DUP (?)
	g_HAND DW ?                     ;文件代号
	g_Offset DW 00H                 ;偏移量
	g_FileEnd   db 0
	BUFFER DB ?                     ;1字节的缓冲区
	;回车 换行 
    g_strEnter  db 0dh, 0ah, '$'
	
	;-------------键盘输入相关的格式  输入1个字符
	g_dbSize_OneCh    db 2                 ;第一个字节为缓冲区的大小(缓冲区的最大长度)    如果超出范围,DOS不让输入,并发出声音
    g_dbLength_OneCh  db 0                   ;第二个字节为实际的长度 (键盘输入后,自动填写)
    g_strBuffer_OneCh db 2 dup (0)         ;从第三个字节开始,为Buffer
	
	
	g_deleteTip db 'input delete index:$'
	g_currentIndex db 0     ;当前查找到了文件的第几个位置
	g_currentDollarIndex db 0   ;当前读取到了文件中第几个 $ 的位置
	g_deleteIndex db 0    ;要删除记录的下标位置,下标从0开始算(第1个$前g_deleteIndex为0)
	g_deleteStartIndex db 0  ;要删除的文件起始位置
	g_deleteEndIndex db 0    ;要删除的文件结束位置
	g_isAllowSet_deleteStartIndex db 1    ;1:允许设置 0:不允许设置    
	g_finish db 0   ;0:继续查找  1:已经查找到下标位置,直接返回函数
MyData ends


MyCode9 segment

DeleteRange proc far ;near
    ;数据段给类型 或者说是 声明数据段
    assume  cs:MyCode9, ds:MyData

    ;---------设置数据段
    mov ax, MyData
    mov ds, ax
	
	;在屏幕上输出 input delete index:
    mov dx, offset g_deleteTip
    mov ah, 09h
    int 21h
	
	;-------------等待用户输入
	;DS:DX=缓冲区首地址
	;(DS:DX+1)=实际输入的字符数
	;(DS:DX)=缓冲区最大字符数
    mov dx, offset g_dbSize_OneCh
    mov ah, 0ah  ;0ah 表示键盘输入到缓冲区
    int 21h
	
	;------保存删除第几条记录
	mov bp,offset g_strBuffer_OneCh
	xor ax,ax
	mov al,ds:[bp]   ;ax 为要删除记录的下标
	mov bx,offset g_deleteIndex
	mov byte ptr ds:[bx],al
	

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
    call ReadCh_M4    ;每次只读取一个字节
	JC ERROR        ;出错跳转
	CMP AL,g_FileEnd     ;读到文件结束符吗？
	JZ NormalFinish       ;是，转
	call ShowCh_M4
	mov bx,offset g_finish
	xor ax,ax
	mov al,byte ptr ds:[bx]
	cmp ax,1
	jz NormalFinish
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
	
	;--------------------- 将 要删除记录的 起始位置 及 结束位置 放到ax里,给调用方使用
	mov ah,g_deleteStartIndex
	mov al,g_deleteEndIndex
    ret 
DeleteRange endp

ReadCh_M4  PROC           ;只读取一个字节

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

ReadCh_M4 ENDP 

ShowCh_M4 PROC 
    inc g_currentIndex      ;每读取一个字节,当前读取位置往后移一个字节
    inc g_deleteEndIndex    ;每读取一个字节,要删除的文件结束位置往后移一个字节

    ;判断文件里面读取的当前字符是否为 $
	cmp al,'$'
	jz IsDoller
	cmp al,'*'
	jz IsStar
	jnz NormalCh
	
NormalCh:
    cmp g_isAllowSet_deleteStartIndex,1    ;如果文件的一开始就是 ******* ,那么,是不能设置起始位置的
	mov bx,offset g_currentIndex
	xor ax,ax
	mov al,byte ptr ds:[bx]
	mov bx,offset g_deleteStartIndex
	mov byte ptr ds:[bx],al    ;将当前位置赋值给要删除的起始位置
	sub g_isAllowSet_deleteStartIndex,1      ;设置不允许给 g_deleteStartIndex(要删除的起始位置) 赋值 
	ret

IsStar:  ;读取到的是 * 
    ;位置的++已经在上面操作了
    ret
	
IsDoller:
    ;到了一条记录的结尾,重新设置 g_deleteStartIndex(要删除的起始位置) 允许赋值
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
    inc g_currentDollarIndex    ;当前在查找的$下标位置++
    ret
findDeleteIndex:
	inc g_finish
    ret
ShowCh_M4 ENDP
    
MyCode9 ends

end











































