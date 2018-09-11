include mylib.inc

MyData segment
    ;-------------键盘输入相关的格式  输入字符串
    g_dbSize_Name    db 80h                 ;第一个字节为缓冲区的大小(缓冲区的最大长度)    如果超出范围,DOS不让输入,并发出声音
    g_dbLength_Name  db 0                   ;第二个字节为实际的长度 (键盘输入后,自动填写)
    g_strBuffer_Name db 80h dup (0)         ;从第三个字节开始,为Buffer
	
	g_dbSize_Age    db 80h                 ;第一个字节为缓冲区的大小(缓冲区的最大长度)    如果超出范围,DOS不让输入,并发出声音
    g_dbLength_Age  db 0                   ;第二个字节为实际的长度 (键盘输入后,自动填写)
    g_strBuffer_Age db 80h dup (0)         ;从第三个字节开始,为Buffer

    g_InputName  db 'input name:$'
	g_InputAge  db 'input phone:$'
	g_Success    db 'write success!$'
	g_Fail    db 'write fail!$'
	;回车 换行 
    g_strEnter  db 0dh, 0ah, '$'

MyData ends


MyCode4 segment

AddStudent proc far ;near

    ;数据段给类型 或者说是 声明数据段
    assume ds : MyData

    ;---------设置数据段
    mov ax, MyData
    mov ds, ax

	;--------------------------------------------------------输入姓名
	;在屏幕上输出 input name:
    mov dx, offset g_InputName
    mov ah, 09h
    int 21h
	
	;-------------等待用户选择对应的菜单选项
	;DS:DX=缓冲区首地址
	;(DS:DX+1)=实际输入的字符数
	;(DS:DX)=缓冲区最大字符数
    mov dx, offset g_dbSize_Name
    mov ah, 0ah  ;0ah 表示键盘输入到缓冲区
    int 21h
	
	;下面要给输入完成的字符串添加结束符$,下面的 bl 存放的是用户实际输入的字符串长度,而加$时,用的是bx,为了将bh置0,这里直接将bx置0.
	xor bx,bx
	;到这一步时,用户已经输入完成,g_dbLength_Name里面已经存入了我们输入的字符串实际长度
	mov bl,g_dbLength_Name           ;默认访问的是 ds 段,所以在上面要声明 ds 在哪一个段 -> assume ds : MyData,这里才可以使用
	;给我们输入的字符串在末尾添加结束符$
	mov si,offset g_strBuffer_Name
	mov byte ptr [si+bx],'$'     ;在这里,姓名后面要拼接年龄,所以这里用 ',' , 而不是'$' , 方便到时候从文件中读取一整条记录
	
	
	;--------------------------------------------------------输入年龄
	
	;回车 换行 
    mov dx, offset g_strEnter
    mov ah, 09h
    int 21h
	
	;在屏幕上输出 input age:
    mov dx, offset g_InputAge
    mov ah, 09h
    int 21h
	
	;-------------等待用户选择对应的菜单选项
	;DS:DX=缓冲区首地址
	;(DS:DX+1)=实际输入的字符数
	;(DS:DX)=缓冲区最大字符数
    mov dx, offset g_dbSize_Age
    mov ah, 0ah  ;0ah 表示键盘输入到缓冲区
    int 21h
	
	;下面要给输入完成的字符串添加结束符$,下面的 bl 存放的是用户实际输入的字符串长度,而加$时,用的是bx,为了将bh置0,这里直接将bx置0.
	xor bx,bx
	;到这一步时,用户已经输入完成,g_dbLength_Age里面已经存入了我们输入的字符串实际长度
	mov bl,g_dbLength_Age           ;默认访问的是 ds 段,所以在上面要声明 ds 在哪一个段 -> assume ds : MyData,这里才可以使用
	;给我们输入的字符串在末尾添加结束符$
	mov si,offset g_strBuffer_Age
	mov byte ptr [si+bx],'$'
	
	;回车 换行 
    mov dx, offset g_strEnter
    mov ah, 09h
    int 21h
	
	
	;------读取输入的菜单选项
	;mov bp,offset g_strBuffer_Age
	;xor ax,ax
	;mov al,ds:[bp]
	;sub ax,'0'      ;将输入的字符ascII转成10进制
	;cmp ax,1
	
	;---------------------------------拼接 姓名+年龄
	;姓名部分
	;下面要给输入完成的字符串添加结束符$,下面的 bl 存放的是用户实际输入的字符串长度,而加$时,用的是bx,为了将bh置0,这里直接将bx置0.
	xor bx,bx
	;到这一步时,用户已经输入完成,g_dbLength_Name里面已经存入了我们输入的字符串实际长度
	mov bl,g_dbLength_Name           ;默认访问的是 ds 段,所以在上面要声明 ds 在哪一个段 -> assume ds : MyData,这里才可以使用
	;给我们输入的字符串在末尾添加结束符$
	mov si,offset g_strBuffer_Name
	
	;年龄部分
	xor ax,ax
	mov al,g_dbLength_Age
	mov di,ax     ;要通过通用寄存器赋值
	mov bp,offset g_strBuffer_Age
	
	lea si,ds:[si+bx]    ;如果不合并,姓名部分,寄存器不够
	
;拼接成如  admin,12$
StrJoinLoop:
    ;年龄部分
    xor cx,cx
	mov cl,byte ptr ds:[bp+di]
	
	;姓名部分
	xor ax,ax
	mov ax,di  ;di在下面有做 减1 操作
	mov bx,ax
	
    mov byte ptr ds:[si+bx+1],cl      ;+1要将附加的$也拼接过去
	sub di,1
	cmp di,0ffffffffh   ;第0个位置也要拼接上去
	jnz StrJoinLoop    ;-----循环处理
	
	xor bx,bx
	mov bl,g_dbLength_Name
	mov si,offset g_strBuffer_Name
	mov byte ptr ds:[si+bx],','      ;因为拼接到了姓名字符串上,所以,去姓名字符串插入一个分隔符

	
	;回车 换行 
    mov dx, offset g_strEnter
    mov ah, 09h
    int 21h
	
	;-----------调用写入文件操作
	;lea ax,offset g_strBuffer_Name
	mov ax,offset g_strBuffer_Name
	;dx:ax存放要写入到文件的字符串首地址
	push ds
	push ax       
	call WriteFile
	
	;判断是否写入文件成功
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
AddStudent endp
    
MyCode4 ends

end





















