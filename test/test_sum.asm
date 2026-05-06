# 파일명: test_sum.asm
# 설명: 두 숫자를 더하고 결과를 출력하는 간단한 프로그램

.data
    # Data Segment (데이터 세그먼트): 변수나 상수가 저장되는 메모리 영역
    prompt: .asciiz "The sum of 15 and 27 is: "  # 출력할 문자열 (Null-terminated)

.text
    # Text Segment (텍스트 세그먼트): 실제 실행될 명령어(Instruction)가 담긴 영역
.globl main

main:
    # 1. 레지스터에 값 로드 및 덧셈 수행
    # ALU(Arithmetic Logic Unit, 산술 논리 장치)를 사용하는 연산입니다.
    li $t0, 15          # li (Load Immediate, 즉시값 로드): $t0 = 15
    li $t1, 27          # li (Load Immediate, 즉시값 로드): $t1 = 27
    add $t2, $t0, $t1   # add (덧셈): $t2 = $t0 + $t1 (결과: 42)

    # 2. "The sum of..." 문자열 출력
    # OS(Operating System, 운영 체제)에 출력을 요청하는 System Call (syscall, 시스템 콜)을 사용합니다.
    li $v0, 4           # 서비스 번호 4: 문자열 출력 (print_string)
    la $a0, prompt      # la (Load Address, 주소 로드): prompt의 메모리 주소를 $a0에 저장
    syscall             # 시스템 호출 실행

    # 3. 계산된 결과($t2) 정수 출력
    li $v0, 1           # 서비스 번호 1: 정수 출력 (print_int)
    move $a0, $t2       # 출력할 값을 $a0 레지스터로 이동
    syscall             # 시스템 호출 실행

    # 4. 프로그램 종료
    li $v0, 10          # 서비스 번호 10: 프로그램 종료 (exit)
    syscall             # 시스템 호출 실행