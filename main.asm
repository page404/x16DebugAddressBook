include mylib.inc

CallDos equ <int 21h>


MyData segment
    ;-------------键盘输入相关的格式  输入字符串
    g_dbSize    db 10h                 ;第一个字节为缓冲区的大小(缓冲区的最大长度)    如果超出范围,DOS不让输入,并发出声音
    g_dbLength  db 0                   ;第二个字节为实际的长度 (键盘输入后,自动填写)
    g_strBuffer db 10h dup (0)         ;从第三个字节开始,为Buffer
	
	;-------------键盘输入相关的格式  输入1个字符
	g_dbSize_OneCh    db 2                 ;第一个字节为缓冲区的大小(缓冲区的最大长度)    如果超出范围,DOS不让输入,并发出声音
    g_dbLength_OneCh  db 0                   ;第二个字节为实际的长度 (键盘输入后,自动填写)
    g_strBuffer_OneCh db 2 dup (0)         ;从第三个字节开始,为Buffer
    
	;回车 换行 
    g_strEnter  db 0dh, 0ah, '$'
    
	;错误提示信息
    g_strError db 'Error input$'
    
MyData ends

MyStack segment stack                     ;stack 声明此处是堆栈段,老的编译器有时候需要此声明
    db 80h dup (0cch)                    ;在g_InitStack前面给同样大小的区域,防止堆栈溢出
    g_InitStack db 80h dup (0cch)        ;定义80h个字节,即十进制100个字节,作为我们的栈空间,以 cc 进行填充. 汇编中的数值,只要是 a到f开头的,前缀必须给0,否则编译器分不清是变量名还是数值.
MyStack ends

MyCode segment

START:
    ;数据段给类型 或者说是 声明数据段
    assume ds : MyData
	
	mov bx, offset g_dbSize
	mov ax,ds:[bx]
	
    ;---------设置数据段
    mov ax, MyData
    mov ds, ax
  
    
	;---------设置堆栈段
    mov ax, MyStack
    mov ss, ax
	;offset 表示取 g_InitStack标号的首地址
	;栈顶设置在栈的中间位置,防止堆栈溢出
    mov sp, offset g_InitStack
	
	
selectMenuLoop:
	
	;------------------输出菜单栏
	call ShowMenu
	
	;回车 换行 
	; mov dx,offset g_strEnter
    ; mov ah, 09h
    ; int 21h
	
	
	
	;------------清空当前的标准输入缓冲区
	;出口参数：若入口参数AL为0AH，则DS:DX＝存放输入字符的起始地
	;mov al,0ah
	;MOV AH,0ch
	;INT 21H
	
	;--------------------------------------------------因为在showMenu里面又设置了数据段的位置,所以,回到这里时,要重新设置本数据段的位置,否则,等待用户选择菜单时,找到的数据段是showMenu.asm里的,就会出错
	;---------设置数据段
    mov ax, MyData
    mov ds, ax
	
	;-------------等待用户选择对应的菜单选项
	;DS:DX=缓冲区首地址
	;(DS:DX+1)=实际输入的字符数
	;(DS:DX)=缓冲区最大字符数
    mov dx, offset g_dbSize_OneCh
    mov ah, 0ah  ;0ah 表示键盘输入到缓冲区
    int 21h
	
	;下面要给输入完成的字符串添加结束符$,下面的 bl 存放的是用户实际输入的字符串长度,而加$时,用的是bx,为了将bh置0,这里直接将bx置0.
	xor bx,bx
	;到这一步时,用户已经输入完成,g_dbLength里面已经存入了我们输入的字符串实际长度
	mov bl,g_dbLength_OneCh           ;默认访问的是 ds 段,所以在上面要声明 ds 在哪一个段 -> assume ds : MyData,这里才可以使用
	;给我们输入的字符串在末尾添加结束符$
	mov si,offset g_strBuffer_OneCh
	mov byte ptr [si+bx],'$'
	
	;回车 换行 
    mov dx, offset g_strEnter
    mov ah, 09h
    int 21h
	
	;-----------将我们键盘输入的字符串输出到屏幕上
	;mov dx,offset g_strBuffer_OneCh
	;mov ah,09h
	;int 21h
	

	;------读取输入的菜单选项
	mov bp,offset g_strBuffer_OneCh
	xor ax,ax
	mov al,ds:[bp]
	sub ax,'0'      ;将输入的字符ascII转成10进制
	cmp ax,1
	jz AddStudentTag   ;跳转到 添加学生 函数
	cmp ax,2
	jz DeleteStudentTag  ;跳转到 删除学生 函数
	cmp ax,4
	jz SearchStudentTag  ;跳转到 查找学生 函数
	cmp ax,5
	jz StudentListTag    ;跳转到 显示学生列表 函数
	cmp ax,6             ;退出程序
	jz EXIT_PROC
	
	
AddStudentTag:
    call AddStudent
	jmp SelectMenuLoop
DeleteStudentTag:
    ;返回的 ah:存放删除文件的起始位置  al:存放删除文件的结束位置
    call DeleteRange
	jmp SelectMenuLoop
StudentListTag:
    call ShowList
	jmp SelectMenuLoop
SearchStudentTag:
    call Search
	jmp SelectMenuLoop
	
    
; return 0
EXIT_PROC:
    mov ax, 4c00h
    int 21h


MyCode ends

end START






