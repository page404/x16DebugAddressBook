include mylib.inc

MyData segment
    ;-------------键盘输入相关的格式  输入字符串
    g_dbSize_Str    db 80h                 ;第一个字节为缓冲区的大小(缓冲区的最大长度)    如果超出范围,DOS不让输入,并发出声音
    g_dbLength_Str  db 0                   ;第二个字节为实际的长度 (键盘输入后,自动填写)
    g_strBuffer_Str db 80h dup (0)         ;从第三个字节开始,为Buffer

    g_SearchTip  db 'input search string:$'
	g_Success    db 'search finish!$'
	g_Fail    db 'no record!$'
	;回车 换行 
    g_strEnter  db 0dh, 0ah, '$'

MyData ends


MyCode8 segment

Search proc far ;near

    ;数据段给类型 或者说是 声明数据段
    assume ds : MyData

    ;---------设置数据段
    mov ax, MyData
    mov ds, ax

	;--------------------------------------------------------输入要查找的信息 (支持模糊查找)
	;在屏幕上输出 input name:
    mov dx, offset g_SearchTip
    mov ah, 09h
    int 21h
	
	;-------------等待用户选择对应的菜单选项
	;DS:DX=缓冲区首地址
	;(DS:DX+1)=实际输入的字符数
	;(DS:DX)=缓冲区最大字符数
    mov dx, offset g_dbSize_Str
    mov ah, 0ah  ;0ah 表示键盘输入到缓冲区
    int 21h
	
	;下面要给输入完成的字符串添加结束符$,下面的 bl 存放的是用户实际输入的字符串长度,而加$时,用的是bx,为了将bh置0,这里直接将bx置0.
	xor bx,bx
	;到这一步时,用户已经输入完成,g_dbLength_Name里面已经存入了我们输入的字符串实际长度
	mov bl,g_dbLength_Str           ;默认访问的是 ds 段,所以在上面要声明 ds 在哪一个段 -> assume ds : MyData,这里才可以使用
	;给我们输入的字符串在末尾添加结束符$
	mov si,offset g_strBuffer_Str
	mov byte ptr [si+bx],'$'     
	
	
	;-----------调用 SearchFile 从文件中查找符合要求的记录
	;lea ax,offset g_strBuffer_Str
	mov ax,offset g_strBuffer_Str
	;dx:ax存放要查找的字符串首地址
	push ds
	push ax       
	call SearchFile
	
	;判断是否查找成功
	cmp ax, 1
	jz actionSuccess
	jnz actionFail

actionFail:
    ;在屏幕上输出
    mov dx, offset g_Fail
    mov ah, 09h
    int 21h

ret 

actionSuccess:
    ;在屏幕上输出
    mov dx, offset g_Success
    mov ah, 09h
    int 21h
	
ret 
Search endp
    
MyCode8 ends

end





















