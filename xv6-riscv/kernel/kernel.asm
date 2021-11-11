
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9a013103          	ld	sp,-1632(sp) # 800089a0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	d9c78793          	addi	a5,a5,-612 # 80005e00 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	554080e7          	jalr	1364(ra) # 80002680 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	01450513          	addi	a0,a0,20 # 800111a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	00448493          	addi	s1,s1,4 # 800111a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	09290913          	addi	s2,s2,146 # 80011238 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	8b0080e7          	jalr	-1872(ra) # 80001a74 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	0b2080e7          	jalr	178(ra) # 80002286 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	41a080e7          	jalr	1050(ra) # 8000262a <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f7c50513          	addi	a0,a0,-132 # 800111a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f6650513          	addi	a0,a0,-154 # 800111a0 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	fcf72323          	sw	a5,-58(a4) # 80011238 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ed450513          	addi	a0,a0,-300 # 800111a0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	3e4080e7          	jalr	996(ra) # 800026d6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ea650513          	addi	a0,a0,-346 # 800111a0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e8270713          	addi	a4,a4,-382 # 800111a0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e5878793          	addi	a5,a5,-424 # 800111a0 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80011238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e1670713          	addi	a4,a4,-490 # 800111a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e0648493          	addi	s1,s1,-506 # 800111a0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	dca70713          	addi	a4,a4,-566 # 800111a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80011240 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d8e78793          	addi	a5,a5,-626 # 800111a0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001123c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dfa50513          	addi	a0,a0,-518 # 80011238 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fcc080e7          	jalr	-52(ra) # 80002412 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d4050513          	addi	a0,a0,-704 # 800111a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	6c078793          	addi	a5,a5,1728 # 80021b38 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80011260 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80011260 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c5050513          	addi	a0,a0,-944 # 80011248 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	aec50513          	addi	a0,a0,-1300 # 80011248 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80011248 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80011268 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80011268 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b72080e7          	jalr	-1166(ra) # 80002412 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80011268 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80011268 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	95a080e7          	jalr	-1702(ra) # 80002286 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	92648493          	addi	s1,s1,-1754 # 80011268 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80011268 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	87490913          	addi	s2,s2,-1932 # 800112a0 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7d850513          	addi	a0,a0,2008 # 800112a0 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	7a248493          	addi	s1,s1,1954 # 800112a0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800112a0 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	75e50513          	addi	a0,a0,1886 # 800112a0 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	eda080e7          	jalr	-294(ra) # 80001a58 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	ea8080e7          	jalr	-344(ra) # 80001a58 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e9c080e7          	jalr	-356(ra) # 80001a58 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	e84080e7          	jalr	-380(ra) # 80001a58 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	e44080e7          	jalr	-444(ra) # 80001a58 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	e18080e7          	jalr	-488(ra) # 80001a58 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	bb2080e7          	jalr	-1102(ra) # 80001a48 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	b96080e7          	jalr	-1130(ra) # 80001a48 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	942080e7          	jalr	-1726(ra) # 80002816 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f64080e7          	jalr	-156(ra) # 80005e40 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	0fc080e7          	jalr	252(ra) # 80001fe0 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	a54080e7          	jalr	-1452(ra) # 80001998 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	8a2080e7          	jalr	-1886(ra) # 800027ee <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	8c2080e7          	jalr	-1854(ra) # 80002816 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	ece080e7          	jalr	-306(ra) # 80005e2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	edc080e7          	jalr	-292(ra) # 80005e40 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	0bc080e7          	jalr	188(ra) # 80003028 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	74c080e7          	jalr	1868(ra) # 800036c0 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	6f6080e7          	jalr	1782(ra) # 80004672 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	fde080e7          	jalr	-34(ra) # 80005f62 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	df8080e7          	jalr	-520(ra) # 80001d84 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	64c080e7          	jalr	1612(ra) # 8000188c <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <rng>:

/* These state variables must be initialised so that they are not all zero. */
uint64 w, x, y, z;

uint64 rng(void) 
{
    8000183e:	1141                	addi	sp,sp,-16
    80001840:	e422                	sd	s0,8(sp)
    80001842:	0800                	addi	s0,sp,16
    uint64 t = x;
    80001844:	00007697          	auipc	a3,0x7
    80001848:	7fc68693          	addi	a3,a3,2044 # 80009040 <x>
    8000184c:	6288                	ld	a0,0(a3)
    t ^= t << 11U;
    8000184e:	00b51793          	slli	a5,a0,0xb
    80001852:	8fa9                	xor	a5,a5,a0
    t ^= t >> 8U;
    x = y; y = z; z = w; 
    80001854:	00007717          	auipc	a4,0x7
    80001858:	7e470713          	addi	a4,a4,2020 # 80009038 <y>
    8000185c:	6310                	ld	a2,0(a4)
    8000185e:	e290                	sd	a2,0(a3)
    80001860:	00007617          	auipc	a2,0x7
    80001864:	7d060613          	addi	a2,a2,2000 # 80009030 <z>
    80001868:	6214                	ld	a3,0(a2)
    8000186a:	e314                	sd	a3,0(a4)
    8000186c:	00007697          	auipc	a3,0x7
    80001870:	7dc68693          	addi	a3,a3,2012 # 80009048 <w>
    80001874:	6298                	ld	a4,0(a3)
    80001876:	e218                	sd	a4,0(a2)
    w ^= w >> 19U;
    80001878:	01375513          	srli	a0,a4,0x13
    8000187c:	8d39                	xor	a0,a0,a4
    w ^= t;
    8000187e:	8d3d                	xor	a0,a0,a5
    t ^= t >> 8U;
    80001880:	83a1                	srli	a5,a5,0x8
    w ^= t;
    80001882:	8d3d                	xor	a0,a0,a5
    80001884:	e288                	sd	a0,0(a3)
    return w;
    80001886:	6422                	ld	s0,8(sp)
    80001888:	0141                	addi	sp,sp,16
    8000188a:	8082                	ret

000000008000188c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000188c:	7139                	addi	sp,sp,-64
    8000188e:	fc06                	sd	ra,56(sp)
    80001890:	f822                	sd	s0,48(sp)
    80001892:	f426                	sd	s1,40(sp)
    80001894:	f04a                	sd	s2,32(sp)
    80001896:	ec4e                	sd	s3,24(sp)
    80001898:	e852                	sd	s4,16(sp)
    8000189a:	e456                	sd	s5,8(sp)
    8000189c:	e05a                	sd	s6,0(sp)
    8000189e:	0080                	addi	s0,sp,64
    800018a0:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a2:	00010497          	auipc	s1,0x10
    800018a6:	e4e48493          	addi	s1,s1,-434 # 800116f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018aa:	8b26                	mv	s6,s1
    800018ac:	00006a97          	auipc	s5,0x6
    800018b0:	754a8a93          	addi	s5,s5,1876 # 80008000 <etext>
    800018b4:	04000937          	lui	s2,0x4000
    800018b8:	197d                	addi	s2,s2,-1
    800018ba:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018bc:	00016a17          	auipc	s4,0x16
    800018c0:	034a0a13          	addi	s4,s4,52 # 800178f0 <tickslock>
    char *pa = kalloc();
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	230080e7          	jalr	560(ra) # 80000af4 <kalloc>
    800018cc:	862a                	mv	a2,a0
    if(pa == 0)
    800018ce:	c131                	beqz	a0,80001912 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018d0:	416485b3          	sub	a1,s1,s6
    800018d4:	858d                	srai	a1,a1,0x3
    800018d6:	000ab783          	ld	a5,0(s5)
    800018da:	02f585b3          	mul	a1,a1,a5
    800018de:	2585                	addiw	a1,a1,1
    800018e0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018e4:	4719                	li	a4,6
    800018e6:	6685                	lui	a3,0x1
    800018e8:	40b905b3          	sub	a1,s2,a1
    800018ec:	854e                	mv	a0,s3
    800018ee:	00000097          	auipc	ra,0x0
    800018f2:	862080e7          	jalr	-1950(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018f6:	18848493          	addi	s1,s1,392
    800018fa:	fd4495e3          	bne	s1,s4,800018c4 <proc_mapstacks+0x38>
  }
}
    800018fe:	70e2                	ld	ra,56(sp)
    80001900:	7442                	ld	s0,48(sp)
    80001902:	74a2                	ld	s1,40(sp)
    80001904:	7902                	ld	s2,32(sp)
    80001906:	69e2                	ld	s3,24(sp)
    80001908:	6a42                	ld	s4,16(sp)
    8000190a:	6aa2                	ld	s5,8(sp)
    8000190c:	6b02                	ld	s6,0(sp)
    8000190e:	6121                	addi	sp,sp,64
    80001910:	8082                	ret
      panic("kalloc");
    80001912:	00007517          	auipc	a0,0x7
    80001916:	8c650513          	addi	a0,a0,-1850 # 800081d8 <digits+0x198>
    8000191a:	fffff097          	auipc	ra,0xfffff
    8000191e:	c24080e7          	jalr	-988(ra) # 8000053e <panic>

0000000080001922 <process_count_print>:
	struct proc *p = myproc();
	int syscallCount = p->syscallCount;
	printf("Number of system calls made by the current process: %d\n", syscallCount);
}

void process_count_print(void){
    80001922:	1141                	addi	sp,sp,-16
    80001924:	e406                	sd	ra,8(sp)
    80001926:	e022                	sd	s0,0(sp)
    80001928:	0800                	addi	s0,sp,16
  struct proc *p;
  int count = 0;
    8000192a:	4581                	li	a1,0
  for(p = proc; p < &proc[NPROC]; p++){
    8000192c:	00010797          	auipc	a5,0x10
    80001930:	dc478793          	addi	a5,a5,-572 # 800116f0 <proc>
    80001934:	00016697          	auipc	a3,0x16
    80001938:	fbc68693          	addi	a3,a3,-68 # 800178f0 <tickslock>
    8000193c:	a029                	j	80001946 <process_count_print+0x24>
    8000193e:	18878793          	addi	a5,a5,392
    80001942:	00d78663          	beq	a5,a3,8000194e <process_count_print+0x2c>
    if(p->state == UNUSED)
    80001946:	4f98                	lw	a4,24(a5)
    80001948:	db7d                	beqz	a4,8000193e <process_count_print+0x1c>
      continue;
    count++;
    8000194a:	2585                	addiw	a1,a1,1
    8000194c:	bfcd                	j	8000193e <process_count_print+0x1c>
  }

  printf("Number of processes in the system: %d\n", count); 
    8000194e:	00007517          	auipc	a0,0x7
    80001952:	89250513          	addi	a0,a0,-1902 # 800081e0 <digits+0x1a0>
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	c32080e7          	jalr	-974(ra) # 80000588 <printf>

}
    8000195e:	60a2                	ld	ra,8(sp)
    80001960:	6402                	ld	s0,0(sp)
    80001962:	0141                	addi	sp,sp,16
    80001964:	8082                	ret

0000000080001966 <mem_pages_count_print>:

void mem_pages_count_print(void){
    80001966:	1141                	addi	sp,sp,-16
    80001968:	e406                	sd	ra,8(sp)
    8000196a:	e022                	sd	s0,0(sp)
    8000196c:	0800                	addi	s0,sp,16
  uint memPagesCount = (PGROUNDUP(proc->sz)) / PGSIZE;
    8000196e:	00010597          	auipc	a1,0x10
    80001972:	dca5b583          	ld	a1,-566(a1) # 80011738 <proc+0x48>
    80001976:	6785                	lui	a5,0x1
    80001978:	17fd                	addi	a5,a5,-1
    8000197a:	95be                	add	a1,a1,a5
    8000197c:	81b1                	srli	a1,a1,0xc
  printf("Number of memory pages: %d\n", memPagesCount);
    8000197e:	2581                	sext.w	a1,a1
    80001980:	00007517          	auipc	a0,0x7
    80001984:	88850513          	addi	a0,a0,-1912 # 80008208 <digits+0x1c8>
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	c00080e7          	jalr	-1024(ra) # 80000588 <printf>
}
    80001990:	60a2                	ld	ra,8(sp)
    80001992:	6402                	ld	s0,0(sp)
    80001994:	0141                	addi	sp,sp,16
    80001996:	8082                	ret

0000000080001998 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001998:	7139                	addi	sp,sp,-64
    8000199a:	fc06                	sd	ra,56(sp)
    8000199c:	f822                	sd	s0,48(sp)
    8000199e:	f426                	sd	s1,40(sp)
    800019a0:	f04a                	sd	s2,32(sp)
    800019a2:	ec4e                	sd	s3,24(sp)
    800019a4:	e852                	sd	s4,16(sp)
    800019a6:	e456                	sd	s5,8(sp)
    800019a8:	e05a                	sd	s6,0(sp)
    800019aa:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019ac:	00007597          	auipc	a1,0x7
    800019b0:	87c58593          	addi	a1,a1,-1924 # 80008228 <digits+0x1e8>
    800019b4:	00010517          	auipc	a0,0x10
    800019b8:	90c50513          	addi	a0,a0,-1780 # 800112c0 <pid_lock>
    800019bc:	fffff097          	auipc	ra,0xfffff
    800019c0:	198080e7          	jalr	408(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019c4:	00007597          	auipc	a1,0x7
    800019c8:	86c58593          	addi	a1,a1,-1940 # 80008230 <digits+0x1f0>
    800019cc:	00010517          	auipc	a0,0x10
    800019d0:	90c50513          	addi	a0,a0,-1780 # 800112d8 <wait_lock>
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	180080e7          	jalr	384(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019dc:	00010497          	auipc	s1,0x10
    800019e0:	d1448493          	addi	s1,s1,-748 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    800019e4:	00007b17          	auipc	s6,0x7
    800019e8:	85cb0b13          	addi	s6,s6,-1956 # 80008240 <digits+0x200>
      p->kstack = KSTACK((int) (p - proc));
    800019ec:	8aa6                	mv	s5,s1
    800019ee:	00006a17          	auipc	s4,0x6
    800019f2:	612a0a13          	addi	s4,s4,1554 # 80008000 <etext>
    800019f6:	04000937          	lui	s2,0x4000
    800019fa:	197d                	addi	s2,s2,-1
    800019fc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019fe:	00016997          	auipc	s3,0x16
    80001a02:	ef298993          	addi	s3,s3,-270 # 800178f0 <tickslock>
      initlock(&p->lock, "proc");
    80001a06:	85da                	mv	a1,s6
    80001a08:	8526                	mv	a0,s1
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	14a080e7          	jalr	330(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a12:	415487b3          	sub	a5,s1,s5
    80001a16:	878d                	srai	a5,a5,0x3
    80001a18:	000a3703          	ld	a4,0(s4)
    80001a1c:	02e787b3          	mul	a5,a5,a4
    80001a20:	2785                	addiw	a5,a5,1
    80001a22:	00d7979b          	slliw	a5,a5,0xd
    80001a26:	40f907b3          	sub	a5,s2,a5
    80001a2a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a2c:	18848493          	addi	s1,s1,392
    80001a30:	fd349be3          	bne	s1,s3,80001a06 <procinit+0x6e>
  }
}
    80001a34:	70e2                	ld	ra,56(sp)
    80001a36:	7442                	ld	s0,48(sp)
    80001a38:	74a2                	ld	s1,40(sp)
    80001a3a:	7902                	ld	s2,32(sp)
    80001a3c:	69e2                	ld	s3,24(sp)
    80001a3e:	6a42                	ld	s4,16(sp)
    80001a40:	6aa2                	ld	s5,8(sp)
    80001a42:	6b02                	ld	s6,0(sp)
    80001a44:	6121                	addi	sp,sp,64
    80001a46:	8082                	ret

0000000080001a48 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a48:	1141                	addi	sp,sp,-16
    80001a4a:	e422                	sd	s0,8(sp)
    80001a4c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a4e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a50:	2501                	sext.w	a0,a0
    80001a52:	6422                	ld	s0,8(sp)
    80001a54:	0141                	addi	sp,sp,16
    80001a56:	8082                	ret

0000000080001a58 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a58:	1141                	addi	sp,sp,-16
    80001a5a:	e422                	sd	s0,8(sp)
    80001a5c:	0800                	addi	s0,sp,16
    80001a5e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a60:	2781                	sext.w	a5,a5
    80001a62:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a64:	00010517          	auipc	a0,0x10
    80001a68:	88c50513          	addi	a0,a0,-1908 # 800112f0 <cpus>
    80001a6c:	953e                	add	a0,a0,a5
    80001a6e:	6422                	ld	s0,8(sp)
    80001a70:	0141                	addi	sp,sp,16
    80001a72:	8082                	ret

0000000080001a74 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	1000                	addi	s0,sp,32
  push_off();
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	11a080e7          	jalr	282(ra) # 80000b98 <push_off>
    80001a86:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a88:	2781                	sext.w	a5,a5
    80001a8a:	079e                	slli	a5,a5,0x7
    80001a8c:	00010717          	auipc	a4,0x10
    80001a90:	83470713          	addi	a4,a4,-1996 # 800112c0 <pid_lock>
    80001a94:	97ba                	add	a5,a5,a4
    80001a96:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	1a0080e7          	jalr	416(ra) # 80000c38 <pop_off>
  return p;
}
    80001aa0:	8526                	mv	a0,s1
    80001aa2:	60e2                	ld	ra,24(sp)
    80001aa4:	6442                	ld	s0,16(sp)
    80001aa6:	64a2                	ld	s1,8(sp)
    80001aa8:	6105                	addi	sp,sp,32
    80001aaa:	8082                	ret

0000000080001aac <syscall_count_print>:
void syscall_count_print(void){
    80001aac:	1141                	addi	sp,sp,-16
    80001aae:	e406                	sd	ra,8(sp)
    80001ab0:	e022                	sd	s0,0(sp)
    80001ab2:	0800                	addi	s0,sp,16
	struct proc *p = myproc();
    80001ab4:	00000097          	auipc	ra,0x0
    80001ab8:	fc0080e7          	jalr	-64(ra) # 80001a74 <myproc>
	printf("Number of system calls made by the current process: %d\n", syscallCount);
    80001abc:	16852583          	lw	a1,360(a0)
    80001ac0:	00006517          	auipc	a0,0x6
    80001ac4:	78850513          	addi	a0,a0,1928 # 80008248 <digits+0x208>
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	ac0080e7          	jalr	-1344(ra) # 80000588 <printf>
}
    80001ad0:	60a2                	ld	ra,8(sp)
    80001ad2:	6402                	ld	s0,0(sp)
    80001ad4:	0141                	addi	sp,sp,16
    80001ad6:	8082                	ret

0000000080001ad8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ad8:	1141                	addi	sp,sp,-16
    80001ada:	e406                	sd	ra,8(sp)
    80001adc:	e022                	sd	s0,0(sp)
    80001ade:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ae0:	00000097          	auipc	ra,0x0
    80001ae4:	f94080e7          	jalr	-108(ra) # 80001a74 <myproc>
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	1b0080e7          	jalr	432(ra) # 80000c98 <release>

  if (first) {
    80001af0:	00007797          	auipc	a5,0x7
    80001af4:	e607a783          	lw	a5,-416(a5) # 80008950 <first.1752>
    80001af8:	eb89                	bnez	a5,80001b0a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001afa:	00001097          	auipc	ra,0x1
    80001afe:	d34080e7          	jalr	-716(ra) # 8000282e <usertrapret>
}
    80001b02:	60a2                	ld	ra,8(sp)
    80001b04:	6402                	ld	s0,0(sp)
    80001b06:	0141                	addi	sp,sp,16
    80001b08:	8082                	ret
    first = 0;
    80001b0a:	00007797          	auipc	a5,0x7
    80001b0e:	e407a323          	sw	zero,-442(a5) # 80008950 <first.1752>
    fsinit(ROOTDEV);
    80001b12:	4505                	li	a0,1
    80001b14:	00002097          	auipc	ra,0x2
    80001b18:	b2c080e7          	jalr	-1236(ra) # 80003640 <fsinit>
    80001b1c:	bff9                	j	80001afa <forkret+0x22>

0000000080001b1e <allocpid>:
allocpid() {
    80001b1e:	1101                	addi	sp,sp,-32
    80001b20:	ec06                	sd	ra,24(sp)
    80001b22:	e822                	sd	s0,16(sp)
    80001b24:	e426                	sd	s1,8(sp)
    80001b26:	e04a                	sd	s2,0(sp)
    80001b28:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b2a:	0000f917          	auipc	s2,0xf
    80001b2e:	79690913          	addi	s2,s2,1942 # 800112c0 <pid_lock>
    80001b32:	854a                	mv	a0,s2
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	0b0080e7          	jalr	176(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b3c:	00007797          	auipc	a5,0x7
    80001b40:	e1878793          	addi	a5,a5,-488 # 80008954 <nextpid>
    80001b44:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b46:	0014871b          	addiw	a4,s1,1
    80001b4a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b4c:	854a                	mv	a0,s2
    80001b4e:	fffff097          	auipc	ra,0xfffff
    80001b52:	14a080e7          	jalr	330(ra) # 80000c98 <release>
}
    80001b56:	8526                	mv	a0,s1
    80001b58:	60e2                	ld	ra,24(sp)
    80001b5a:	6442                	ld	s0,16(sp)
    80001b5c:	64a2                	ld	s1,8(sp)
    80001b5e:	6902                	ld	s2,0(sp)
    80001b60:	6105                	addi	sp,sp,32
    80001b62:	8082                	ret

0000000080001b64 <proc_pagetable>:
{
    80001b64:	1101                	addi	sp,sp,-32
    80001b66:	ec06                	sd	ra,24(sp)
    80001b68:	e822                	sd	s0,16(sp)
    80001b6a:	e426                	sd	s1,8(sp)
    80001b6c:	e04a                	sd	s2,0(sp)
    80001b6e:	1000                	addi	s0,sp,32
    80001b70:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	7c8080e7          	jalr	1992(ra) # 8000133a <uvmcreate>
    80001b7a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b7c:	c121                	beqz	a0,80001bbc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b7e:	4729                	li	a4,10
    80001b80:	00005697          	auipc	a3,0x5
    80001b84:	48068693          	addi	a3,a3,1152 # 80007000 <_trampoline>
    80001b88:	6605                	lui	a2,0x1
    80001b8a:	040005b7          	lui	a1,0x4000
    80001b8e:	15fd                	addi	a1,a1,-1
    80001b90:	05b2                	slli	a1,a1,0xc
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	51e080e7          	jalr	1310(ra) # 800010b0 <mappages>
    80001b9a:	02054863          	bltz	a0,80001bca <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b9e:	4719                	li	a4,6
    80001ba0:	05893683          	ld	a3,88(s2)
    80001ba4:	6605                	lui	a2,0x1
    80001ba6:	020005b7          	lui	a1,0x2000
    80001baa:	15fd                	addi	a1,a1,-1
    80001bac:	05b6                	slli	a1,a1,0xd
    80001bae:	8526                	mv	a0,s1
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	500080e7          	jalr	1280(ra) # 800010b0 <mappages>
    80001bb8:	02054163          	bltz	a0,80001bda <proc_pagetable+0x76>
}
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	60e2                	ld	ra,24(sp)
    80001bc0:	6442                	ld	s0,16(sp)
    80001bc2:	64a2                	ld	s1,8(sp)
    80001bc4:	6902                	ld	s2,0(sp)
    80001bc6:	6105                	addi	sp,sp,32
    80001bc8:	8082                	ret
    uvmfree(pagetable, 0);
    80001bca:	4581                	li	a1,0
    80001bcc:	8526                	mv	a0,s1
    80001bce:	00000097          	auipc	ra,0x0
    80001bd2:	968080e7          	jalr	-1688(ra) # 80001536 <uvmfree>
    return 0;
    80001bd6:	4481                	li	s1,0
    80001bd8:	b7d5                	j	80001bbc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bda:	4681                	li	a3,0
    80001bdc:	4605                	li	a2,1
    80001bde:	040005b7          	lui	a1,0x4000
    80001be2:	15fd                	addi	a1,a1,-1
    80001be4:	05b2                	slli	a1,a1,0xc
    80001be6:	8526                	mv	a0,s1
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	68e080e7          	jalr	1678(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001bf0:	4581                	li	a1,0
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	00000097          	auipc	ra,0x0
    80001bf8:	942080e7          	jalr	-1726(ra) # 80001536 <uvmfree>
    return 0;
    80001bfc:	4481                	li	s1,0
    80001bfe:	bf7d                	j	80001bbc <proc_pagetable+0x58>

0000000080001c00 <proc_freepagetable>:
{
    80001c00:	1101                	addi	sp,sp,-32
    80001c02:	ec06                	sd	ra,24(sp)
    80001c04:	e822                	sd	s0,16(sp)
    80001c06:	e426                	sd	s1,8(sp)
    80001c08:	e04a                	sd	s2,0(sp)
    80001c0a:	1000                	addi	s0,sp,32
    80001c0c:	84aa                	mv	s1,a0
    80001c0e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c10:	4681                	li	a3,0
    80001c12:	4605                	li	a2,1
    80001c14:	040005b7          	lui	a1,0x4000
    80001c18:	15fd                	addi	a1,a1,-1
    80001c1a:	05b2                	slli	a1,a1,0xc
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	65a080e7          	jalr	1626(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c24:	4681                	li	a3,0
    80001c26:	4605                	li	a2,1
    80001c28:	020005b7          	lui	a1,0x2000
    80001c2c:	15fd                	addi	a1,a1,-1
    80001c2e:	05b6                	slli	a1,a1,0xd
    80001c30:	8526                	mv	a0,s1
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	644080e7          	jalr	1604(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c3a:	85ca                	mv	a1,s2
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	8f8080e7          	jalr	-1800(ra) # 80001536 <uvmfree>
}
    80001c46:	60e2                	ld	ra,24(sp)
    80001c48:	6442                	ld	s0,16(sp)
    80001c4a:	64a2                	ld	s1,8(sp)
    80001c4c:	6902                	ld	s2,0(sp)
    80001c4e:	6105                	addi	sp,sp,32
    80001c50:	8082                	ret

0000000080001c52 <freeproc>:
{
    80001c52:	1101                	addi	sp,sp,-32
    80001c54:	ec06                	sd	ra,24(sp)
    80001c56:	e822                	sd	s0,16(sp)
    80001c58:	e426                	sd	s1,8(sp)
    80001c5a:	1000                	addi	s0,sp,32
    80001c5c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c5e:	6d28                	ld	a0,88(a0)
    80001c60:	c509                	beqz	a0,80001c6a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	d96080e7          	jalr	-618(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001c6a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c6e:	68a8                	ld	a0,80(s1)
    80001c70:	c511                	beqz	a0,80001c7c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c72:	64ac                	ld	a1,72(s1)
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	f8c080e7          	jalr	-116(ra) # 80001c00 <proc_freepagetable>
  p->pagetable = 0;
    80001c7c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c80:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c84:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c88:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c8c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c90:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c94:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c98:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c9c:	0004ac23          	sw	zero,24(s1)
}
    80001ca0:	60e2                	ld	ra,24(sp)
    80001ca2:	6442                	ld	s0,16(sp)
    80001ca4:	64a2                	ld	s1,8(sp)
    80001ca6:	6105                	addi	sp,sp,32
    80001ca8:	8082                	ret

0000000080001caa <allocproc>:
{
    80001caa:	1101                	addi	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	e04a                	sd	s2,0(sp)
    80001cb4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cb6:	00010497          	auipc	s1,0x10
    80001cba:	a3a48493          	addi	s1,s1,-1478 # 800116f0 <proc>
    80001cbe:	00016917          	auipc	s2,0x16
    80001cc2:	c3290913          	addi	s2,s2,-974 # 800178f0 <tickslock>
    acquire(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	f1c080e7          	jalr	-228(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001cd0:	4c9c                	lw	a5,24(s1)
    80001cd2:	cf81                	beqz	a5,80001cea <allocproc+0x40>
      release(&p->lock);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	fc2080e7          	jalr	-62(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cde:	18848493          	addi	s1,s1,392
    80001ce2:	ff2492e3          	bne	s1,s2,80001cc6 <allocproc+0x1c>
  return 0;
    80001ce6:	4481                	li	s1,0
    80001ce8:	a8b9                	j	80001d46 <allocproc+0x9c>
  p->syscallCount = 0;
    80001cea:	1604b423          	sd	zero,360(s1)
  p->pid = allocpid();
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	e30080e7          	jalr	-464(ra) # 80001b1e <allocpid>
    80001cf6:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001cf8:	4785                	li	a5,1
    80001cfa:	cc9c                	sw	a5,24(s1)
  p->ticks = 0;
    80001cfc:	1604bc23          	sd	zero,376(s1)
  p->tickets = 0;
    80001d00:	1604b823          	sd	zero,368(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	df0080e7          	jalr	-528(ra) # 80000af4 <kalloc>
    80001d0c:	892a                	mv	s2,a0
    80001d0e:	eca8                	sd	a0,88(s1)
    80001d10:	c131                	beqz	a0,80001d54 <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	e50080e7          	jalr	-432(ra) # 80001b64 <proc_pagetable>
    80001d1c:	892a                	mv	s2,a0
    80001d1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d20:	c531                	beqz	a0,80001d6c <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001d22:	07000613          	li	a2,112
    80001d26:	4581                	li	a1,0
    80001d28:	06048513          	addi	a0,s1,96
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	fb4080e7          	jalr	-76(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d34:	00000797          	auipc	a5,0x0
    80001d38:	da478793          	addi	a5,a5,-604 # 80001ad8 <forkret>
    80001d3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d3e:	60bc                	ld	a5,64(s1)
    80001d40:	6705                	lui	a4,0x1
    80001d42:	97ba                	add	a5,a5,a4
    80001d44:	f4bc                	sd	a5,104(s1)
}
    80001d46:	8526                	mv	a0,s1
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6902                	ld	s2,0(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret
    freeproc(p);
    80001d54:	8526                	mv	a0,s1
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	efc080e7          	jalr	-260(ra) # 80001c52 <freeproc>
    release(&p->lock);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	f38080e7          	jalr	-200(ra) # 80000c98 <release>
    return 0;
    80001d68:	84ca                	mv	s1,s2
    80001d6a:	bff1                	j	80001d46 <allocproc+0x9c>
    freeproc(p);
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	ee4080e7          	jalr	-284(ra) # 80001c52 <freeproc>
    release(&p->lock);
    80001d76:	8526                	mv	a0,s1
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	f20080e7          	jalr	-224(ra) # 80000c98 <release>
    return 0;
    80001d80:	84ca                	mv	s1,s2
    80001d82:	b7d1                	j	80001d46 <allocproc+0x9c>

0000000080001d84 <userinit>:
{
    80001d84:	1101                	addi	sp,sp,-32
    80001d86:	ec06                	sd	ra,24(sp)
    80001d88:	e822                	sd	s0,16(sp)
    80001d8a:	e426                	sd	s1,8(sp)
    80001d8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	f1c080e7          	jalr	-228(ra) # 80001caa <allocproc>
    80001d96:	84aa                	mv	s1,a0
  initproc = p;
    80001d98:	00007797          	auipc	a5,0x7
    80001d9c:	28a7b823          	sd	a0,656(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001da0:	03400613          	li	a2,52
    80001da4:	00007597          	auipc	a1,0x7
    80001da8:	bbc58593          	addi	a1,a1,-1092 # 80008960 <initcode>
    80001dac:	6928                	ld	a0,80(a0)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	5ba080e7          	jalr	1466(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001db6:	6785                	lui	a5,0x1
    80001db8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dba:	6cb8                	ld	a4,88(s1)
    80001dbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dc0:	6cb8                	ld	a4,88(s1)
    80001dc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dc4:	4641                	li	a2,16
    80001dc6:	00006597          	auipc	a1,0x6
    80001dca:	4ba58593          	addi	a1,a1,1210 # 80008280 <digits+0x240>
    80001dce:	15848513          	addi	a0,s1,344
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	060080e7          	jalr	96(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001dda:	00006517          	auipc	a0,0x6
    80001dde:	4b650513          	addi	a0,a0,1206 # 80008290 <digits+0x250>
    80001de2:	00002097          	auipc	ra,0x2
    80001de6:	28c080e7          	jalr	652(ra) # 8000406e <namei>
    80001dea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001dee:	478d                	li	a5,3
    80001df0:	cc9c                	sw	a5,24(s1)
  p->pass = 0; //always initialize pass to 0
    80001df2:	1804a223          	sw	zero,388(s1)
  p->tickets = DEFAULT_TICKET_ALLOTTMENT; //default ticket constant (for now)
    80001df6:	03200793          	li	a5,50
    80001dfa:	16f4b823          	sd	a5,368(s1)
  	p->stride = (MAX_STRIDE_C) / (p->tickets);
    80001dfe:	32000793          	li	a5,800
    80001e02:	18f4a023          	sw	a5,384(s1)
  release(&p->lock);
    80001e06:	8526                	mv	a0,s1
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	e90080e7          	jalr	-368(ra) # 80000c98 <release>
}
    80001e10:	60e2                	ld	ra,24(sp)
    80001e12:	6442                	ld	s0,16(sp)
    80001e14:	64a2                	ld	s1,8(sp)
    80001e16:	6105                	addi	sp,sp,32
    80001e18:	8082                	ret

0000000080001e1a <growproc>:
{
    80001e1a:	1101                	addi	sp,sp,-32
    80001e1c:	ec06                	sd	ra,24(sp)
    80001e1e:	e822                	sd	s0,16(sp)
    80001e20:	e426                	sd	s1,8(sp)
    80001e22:	e04a                	sd	s2,0(sp)
    80001e24:	1000                	addi	s0,sp,32
    80001e26:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e28:	00000097          	auipc	ra,0x0
    80001e2c:	c4c080e7          	jalr	-948(ra) # 80001a74 <myproc>
    80001e30:	892a                	mv	s2,a0
  sz = p->sz;
    80001e32:	652c                	ld	a1,72(a0)
    80001e34:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e38:	00904f63          	bgtz	s1,80001e56 <growproc+0x3c>
  } else if(n < 0){
    80001e3c:	0204cc63          	bltz	s1,80001e74 <growproc+0x5a>
  p->sz = sz;
    80001e40:	1602                	slli	a2,a2,0x20
    80001e42:	9201                	srli	a2,a2,0x20
    80001e44:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e48:	4501                	li	a0,0
}
    80001e4a:	60e2                	ld	ra,24(sp)
    80001e4c:	6442                	ld	s0,16(sp)
    80001e4e:	64a2                	ld	s1,8(sp)
    80001e50:	6902                	ld	s2,0(sp)
    80001e52:	6105                	addi	sp,sp,32
    80001e54:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e56:	9e25                	addw	a2,a2,s1
    80001e58:	1602                	slli	a2,a2,0x20
    80001e5a:	9201                	srli	a2,a2,0x20
    80001e5c:	1582                	slli	a1,a1,0x20
    80001e5e:	9181                	srli	a1,a1,0x20
    80001e60:	6928                	ld	a0,80(a0)
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	5c0080e7          	jalr	1472(ra) # 80001422 <uvmalloc>
    80001e6a:	0005061b          	sext.w	a2,a0
    80001e6e:	fa69                	bnez	a2,80001e40 <growproc+0x26>
      return -1;
    80001e70:	557d                	li	a0,-1
    80001e72:	bfe1                	j	80001e4a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e74:	9e25                	addw	a2,a2,s1
    80001e76:	1602                	slli	a2,a2,0x20
    80001e78:	9201                	srli	a2,a2,0x20
    80001e7a:	1582                	slli	a1,a1,0x20
    80001e7c:	9181                	srli	a1,a1,0x20
    80001e7e:	6928                	ld	a0,80(a0)
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	55a080e7          	jalr	1370(ra) # 800013da <uvmdealloc>
    80001e88:	0005061b          	sext.w	a2,a0
    80001e8c:	bf55                	j	80001e40 <growproc+0x26>

0000000080001e8e <fork>:
{
    80001e8e:	7179                	addi	sp,sp,-48
    80001e90:	f406                	sd	ra,40(sp)
    80001e92:	f022                	sd	s0,32(sp)
    80001e94:	ec26                	sd	s1,24(sp)
    80001e96:	e84a                	sd	s2,16(sp)
    80001e98:	e44e                	sd	s3,8(sp)
    80001e9a:	e052                	sd	s4,0(sp)
    80001e9c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	bd6080e7          	jalr	-1066(ra) # 80001a74 <myproc>
    80001ea6:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	e02080e7          	jalr	-510(ra) # 80001caa <allocproc>
    80001eb0:	12050663          	beqz	a0,80001fdc <fork+0x14e>
    80001eb4:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eb6:	0489b603          	ld	a2,72(s3)
    80001eba:	692c                	ld	a1,80(a0)
    80001ebc:	0509b503          	ld	a0,80(s3)
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	6ae080e7          	jalr	1710(ra) # 8000156e <uvmcopy>
    80001ec8:	04054663          	bltz	a0,80001f14 <fork+0x86>
  np->sz = p->sz;
    80001ecc:	0489b783          	ld	a5,72(s3)
    80001ed0:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    80001ed4:	0589b683          	ld	a3,88(s3)
    80001ed8:	87b6                	mv	a5,a3
    80001eda:	05893703          	ld	a4,88(s2)
    80001ede:	12068693          	addi	a3,a3,288
    80001ee2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ee6:	6788                	ld	a0,8(a5)
    80001ee8:	6b8c                	ld	a1,16(a5)
    80001eea:	6f90                	ld	a2,24(a5)
    80001eec:	01073023          	sd	a6,0(a4)
    80001ef0:	e708                	sd	a0,8(a4)
    80001ef2:	eb0c                	sd	a1,16(a4)
    80001ef4:	ef10                	sd	a2,24(a4)
    80001ef6:	02078793          	addi	a5,a5,32
    80001efa:	02070713          	addi	a4,a4,32
    80001efe:	fed792e3          	bne	a5,a3,80001ee2 <fork+0x54>
  np->trapframe->a0 = 0;
    80001f02:	05893783          	ld	a5,88(s2)
    80001f06:	0607b823          	sd	zero,112(a5)
    80001f0a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f0e:	15000a13          	li	s4,336
    80001f12:	a03d                	j	80001f40 <fork+0xb2>
    freeproc(np);
    80001f14:	854a                	mv	a0,s2
    80001f16:	00000097          	auipc	ra,0x0
    80001f1a:	d3c080e7          	jalr	-708(ra) # 80001c52 <freeproc>
    release(&np->lock);
    80001f1e:	854a                	mv	a0,s2
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	d78080e7          	jalr	-648(ra) # 80000c98 <release>
    return -1;
    80001f28:	5a7d                	li	s4,-1
    80001f2a:	a045                	j	80001fca <fork+0x13c>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f2c:	00002097          	auipc	ra,0x2
    80001f30:	7d8080e7          	jalr	2008(ra) # 80004704 <filedup>
    80001f34:	009907b3          	add	a5,s2,s1
    80001f38:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f3a:	04a1                	addi	s1,s1,8
    80001f3c:	01448763          	beq	s1,s4,80001f4a <fork+0xbc>
    if(p->ofile[i])
    80001f40:	009987b3          	add	a5,s3,s1
    80001f44:	6388                	ld	a0,0(a5)
    80001f46:	f17d                	bnez	a0,80001f2c <fork+0x9e>
    80001f48:	bfcd                	j	80001f3a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f4a:	1509b503          	ld	a0,336(s3)
    80001f4e:	00002097          	auipc	ra,0x2
    80001f52:	92c080e7          	jalr	-1748(ra) # 8000387a <idup>
    80001f56:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f5a:	4641                	li	a2,16
    80001f5c:	15898593          	addi	a1,s3,344
    80001f60:	15890513          	addi	a0,s2,344
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	ece080e7          	jalr	-306(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f6c:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    80001f70:	854a                	mv	a0,s2
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	d26080e7          	jalr	-730(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f7a:	0000f497          	auipc	s1,0xf
    80001f7e:	35e48493          	addi	s1,s1,862 # 800112d8 <wait_lock>
    80001f82:	8526                	mv	a0,s1
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	c60080e7          	jalr	-928(ra) # 80000be4 <acquire>
  np->parent = p;
    80001f8c:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80001f90:	8526                	mv	a0,s1
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	d06080e7          	jalr	-762(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f9a:	854a                	mv	a0,s2
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	c48080e7          	jalr	-952(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001fa4:	478d                	li	a5,3
    80001fa6:	00f92c23          	sw	a5,24(s2)
  np->stride = MAX_STRIDE_C /  np->tickets;
    80001faa:	17093703          	ld	a4,368(s2)
    80001fae:	67a9                	lui	a5,0xa
    80001fb0:	c4078793          	addi	a5,a5,-960 # 9c40 <_entry-0x7fff63c0>
    80001fb4:	02e7d7b3          	divu	a5,a5,a4
    80001fb8:	18f92023          	sw	a5,384(s2)
  np->pass = 0;
    80001fbc:	18092223          	sw	zero,388(s2)
  release(&np->lock);
    80001fc0:	854a                	mv	a0,s2
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	cd6080e7          	jalr	-810(ra) # 80000c98 <release>
}
    80001fca:	8552                	mv	a0,s4
    80001fcc:	70a2                	ld	ra,40(sp)
    80001fce:	7402                	ld	s0,32(sp)
    80001fd0:	64e2                	ld	s1,24(sp)
    80001fd2:	6942                	ld	s2,16(sp)
    80001fd4:	69a2                	ld	s3,8(sp)
    80001fd6:	6a02                	ld	s4,0(sp)
    80001fd8:	6145                	addi	sp,sp,48
    80001fda:	8082                	ret
    return -1;
    80001fdc:	5a7d                	li	s4,-1
    80001fde:	b7f5                	j	80001fca <fork+0x13c>

0000000080001fe0 <scheduler>:
{
    80001fe0:	7119                	addi	sp,sp,-128
    80001fe2:	fc86                	sd	ra,120(sp)
    80001fe4:	f8a2                	sd	s0,112(sp)
    80001fe6:	f4a6                	sd	s1,104(sp)
    80001fe8:	f0ca                	sd	s2,96(sp)
    80001fea:	ecce                	sd	s3,88(sp)
    80001fec:	e8d2                	sd	s4,80(sp)
    80001fee:	e4d6                	sd	s5,72(sp)
    80001ff0:	e0da                	sd	s6,64(sp)
    80001ff2:	fc5e                	sd	s7,56(sp)
    80001ff4:	f862                	sd	s8,48(sp)
    80001ff6:	f466                	sd	s9,40(sp)
    80001ff8:	f06a                	sd	s10,32(sp)
    80001ffa:	ec6e                	sd	s11,24(sp)
    80001ffc:	0100                	addi	s0,sp,128
    80001ffe:	8792                	mv	a5,tp
  int id = r_tp();
    80002000:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002002:	00779693          	slli	a3,a5,0x7
    80002006:	0000f717          	auipc	a4,0xf
    8000200a:	2ba70713          	addi	a4,a4,698 # 800112c0 <pid_lock>
    8000200e:	9736                	add	a4,a4,a3
    80002010:	02073823          	sd	zero,48(a4)
		    swtch(&c->context, &p->context);
    80002014:	0000f717          	auipc	a4,0xf
    80002018:	2e470713          	addi	a4,a4,740 # 800112f8 <cpus+0x8>
    8000201c:	9736                	add	a4,a4,a3
    8000201e:	f8e43423          	sd	a4,-120(s0)
		if(p->state == RUNNABLE) {
    80002022:	4a0d                	li	s4,3
	for(p = proc; p < &proc[NPROC]; p++){
    80002024:	00016a97          	auipc	s5,0x16
    80002028:	8cca8a93          	addi	s5,s5,-1844 # 800178f0 <tickslock>
    int max_stride = MAX_STRIDE_C;
    8000202c:	6ca9                	lui	s9,0xa
    8000202e:	c40c8c93          	addi	s9,s9,-960 # 9c40 <_entry-0x7fff63c0>
		    c->proc = p;
    80002032:	0000fd97          	auipc	s11,0xf
    80002036:	28ed8d93          	addi	s11,s11,654 # 800112c0 <pid_lock>
    8000203a:	9db6                	add	s11,s11,a3
    8000203c:	a855                	j	800020f0 <scheduler+0x110>
		release(&p->lock);
    8000203e:	854a                	mv	a0,s2
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	c58080e7          	jalr	-936(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++){
    80002048:	18848993          	addi	s3,s1,392
    8000204c:	0359fd63          	bgeu	s3,s5,80002086 <scheduler+0xa6>
    80002050:	18848493          	addi	s1,s1,392
    80002054:	8926                	mv	s2,s1
		acquire(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	b8c080e7          	jalr	-1140(ra) # 80000be4 <acquire>
		if(p->state == RUNNABLE) {
    80002060:	4c9c                	lw	a5,24(s1)
    80002062:	fd479ee3          	bne	a5,s4,8000203e <scheduler+0x5e>
			if (p->pass < max_stride){
    80002066:	1844ab03          	lw	s6,388(s1)
    8000206a:	fd7b5ae3          	bge	s6,s7,8000203e <scheduler+0x5e>
		release(&p->lock);
    8000206e:	8526                	mv	a0,s1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	c28080e7          	jalr	-984(ra) # 80000c98 <release>
	for(p = proc; p < &proc[NPROC]; p++){
    80002078:	18848993          	addi	s3,s1,392
    8000207c:	0359f563          	bgeu	s3,s5,800020a6 <scheduler+0xc6>
    80002080:	8c4a                	mv	s8,s2
				max_stride = p->pass;
    80002082:	8bda                	mv	s7,s6
    80002084:	b7f1                	j	80002050 <scheduler+0x70>
	if(minProc){
    80002086:	000c1f63          	bnez	s8,800020a4 <scheduler+0xc4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000208a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000208e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002092:	10079073          	csrw	sstatus,a5
	for(p = proc; p < &proc[NPROC]; p++){
    80002096:	0000f497          	auipc	s1,0xf
    8000209a:	65a48493          	addi	s1,s1,1626 # 800116f0 <proc>
    struct proc *minProc = 0;
    8000209e:	8c6a                	mv	s8,s10
    int max_stride = MAX_STRIDE_C;
    800020a0:	8be6                	mv	s7,s9
    800020a2:	bf4d                	j	80002054 <scheduler+0x74>
    800020a4:	8962                	mv	s2,s8
		acquire(&p->lock);
    800020a6:	854e                	mv	a0,s3
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	b3c080e7          	jalr	-1220(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE){
    800020b0:	0189a783          	lw	a5,24(s3)
    800020b4:	03479963          	bne	a5,s4,800020e6 <scheduler+0x106>
		    p->pass += p->stride;
    800020b8:	18492783          	lw	a5,388(s2)
    800020bc:	18092703          	lw	a4,384(s2)
    800020c0:	9fb9                	addw	a5,a5,a4
    800020c2:	18f92223          	sw	a5,388(s2)
		    p->state = RUNNING; 
    800020c6:	4791                	li	a5,4
    800020c8:	00f92c23          	sw	a5,24(s2)
		    c->proc = p;
    800020cc:	032db823          	sd	s2,48(s11)
		    swtch(&c->context, &p->context);
    800020d0:	06090593          	addi	a1,s2,96
    800020d4:	f8843503          	ld	a0,-120(s0)
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	6ac080e7          	jalr	1708(ra) # 80002784 <swtch>
		    c->proc = 0;
    800020e0:	020db823          	sd	zero,48(s11)
    800020e4:	89ca                	mv	s3,s2
		release(&p->lock);
    800020e6:	854e                	mv	a0,s3
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	bb0080e7          	jalr	-1104(ra) # 80000c98 <release>
    struct proc *minProc = 0;
    800020f0:	4d01                	li	s10,0
    800020f2:	bf61                	j	8000208a <scheduler+0xaa>

00000000800020f4 <set_tickets>:
{
    800020f4:	1101                	addi	sp,sp,-32
    800020f6:	ec06                	sd	ra,24(sp)
    800020f8:	e822                	sd	s0,16(sp)
    800020fa:	e426                	sd	s1,8(sp)
    800020fc:	e04a                	sd	s2,0(sp)
    800020fe:	1000                	addi	s0,sp,32
    80002100:	892a                	mv	s2,a0
	struct proc *p = myproc();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	972080e7          	jalr	-1678(ra) # 80001a74 <myproc>
    8000210a:	84aa                	mv	s1,a0
	acquire(&p->lock);
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	ad8080e7          	jalr	-1320(ra) # 80000be4 <acquire>
	p->tickets = tickets;
    80002114:	1724b823          	sd	s2,368(s1)
	release(&p->lock);
    80002118:	8526                	mv	a0,s1
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	b7e080e7          	jalr	-1154(ra) # 80000c98 <release>
}
    80002122:	60e2                	ld	ra,24(sp)
    80002124:	6442                	ld	s0,16(sp)
    80002126:	64a2                	ld	s1,8(sp)
    80002128:	6902                	ld	s2,0(sp)
    8000212a:	6105                	addi	sp,sp,32
    8000212c:	8082                	ret

000000008000212e <sched_statistics>:
{
    8000212e:	1101                	addi	sp,sp,-32
    80002130:	ec06                	sd	ra,24(sp)
    80002132:	e822                	sd	s0,16(sp)
    80002134:	e426                	sd	s1,8(sp)
    80002136:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002138:	00000097          	auipc	ra,0x0
    8000213c:	93c080e7          	jalr	-1732(ra) # 80001a74 <myproc>
  uint64 tickets = p->tickets;
    80002140:	17053483          	ld	s1,368(a0)
  printf("Current process\'s number of ticks: %d\n", ticks);
    80002144:	17853583          	ld	a1,376(a0)
    80002148:	00006517          	auipc	a0,0x6
    8000214c:	15050513          	addi	a0,a0,336 # 80008298 <digits+0x258>
    80002150:	ffffe097          	auipc	ra,0xffffe
    80002154:	438080e7          	jalr	1080(ra) # 80000588 <printf>
  printf("Current process\'s number of tickets: %d\n", tickets);
    80002158:	85a6                	mv	a1,s1
    8000215a:	00006517          	auipc	a0,0x6
    8000215e:	16650513          	addi	a0,a0,358 # 800082c0 <digits+0x280>
    80002162:	ffffe097          	auipc	ra,0xffffe
    80002166:	426080e7          	jalr	1062(ra) # 80000588 <printf>
}
    8000216a:	60e2                	ld	ra,24(sp)
    8000216c:	6442                	ld	s0,16(sp)
    8000216e:	64a2                	ld	s1,8(sp)
    80002170:	6105                	addi	sp,sp,32
    80002172:	8082                	ret

0000000080002174 <sched>:
{
    80002174:	7179                	addi	sp,sp,-48
    80002176:	f406                	sd	ra,40(sp)
    80002178:	f022                	sd	s0,32(sp)
    8000217a:	ec26                	sd	s1,24(sp)
    8000217c:	e84a                	sd	s2,16(sp)
    8000217e:	e44e                	sd	s3,8(sp)
    80002180:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002182:	00000097          	auipc	ra,0x0
    80002186:	8f2080e7          	jalr	-1806(ra) # 80001a74 <myproc>
    8000218a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	9de080e7          	jalr	-1570(ra) # 80000b6a <holding>
    80002194:	c93d                	beqz	a0,8000220a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002196:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002198:	2781                	sext.w	a5,a5
    8000219a:	079e                	slli	a5,a5,0x7
    8000219c:	0000f717          	auipc	a4,0xf
    800021a0:	12470713          	addi	a4,a4,292 # 800112c0 <pid_lock>
    800021a4:	97ba                	add	a5,a5,a4
    800021a6:	0a87a703          	lw	a4,168(a5)
    800021aa:	4785                	li	a5,1
    800021ac:	06f71763          	bne	a4,a5,8000221a <sched+0xa6>
  if(p->state == RUNNING)
    800021b0:	4c98                	lw	a4,24(s1)
    800021b2:	4791                	li	a5,4
    800021b4:	06f70b63          	beq	a4,a5,8000222a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021b8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021bc:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021be:	efb5                	bnez	a5,8000223a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021c0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021c2:	0000f917          	auipc	s2,0xf
    800021c6:	0fe90913          	addi	s2,s2,254 # 800112c0 <pid_lock>
    800021ca:	2781                	sext.w	a5,a5
    800021cc:	079e                	slli	a5,a5,0x7
    800021ce:	97ca                	add	a5,a5,s2
    800021d0:	0ac7a983          	lw	s3,172(a5)
    800021d4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021d6:	2781                	sext.w	a5,a5
    800021d8:	079e                	slli	a5,a5,0x7
    800021da:	0000f597          	auipc	a1,0xf
    800021de:	11e58593          	addi	a1,a1,286 # 800112f8 <cpus+0x8>
    800021e2:	95be                	add	a1,a1,a5
    800021e4:	06048513          	addi	a0,s1,96
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	59c080e7          	jalr	1436(ra) # 80002784 <swtch>
    800021f0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021f2:	2781                	sext.w	a5,a5
    800021f4:	079e                	slli	a5,a5,0x7
    800021f6:	97ca                	add	a5,a5,s2
    800021f8:	0b37a623          	sw	s3,172(a5)
}
    800021fc:	70a2                	ld	ra,40(sp)
    800021fe:	7402                	ld	s0,32(sp)
    80002200:	64e2                	ld	s1,24(sp)
    80002202:	6942                	ld	s2,16(sp)
    80002204:	69a2                	ld	s3,8(sp)
    80002206:	6145                	addi	sp,sp,48
    80002208:	8082                	ret
    panic("sched p->lock");
    8000220a:	00006517          	auipc	a0,0x6
    8000220e:	0e650513          	addi	a0,a0,230 # 800082f0 <digits+0x2b0>
    80002212:	ffffe097          	auipc	ra,0xffffe
    80002216:	32c080e7          	jalr	812(ra) # 8000053e <panic>
    panic("sched locks");
    8000221a:	00006517          	auipc	a0,0x6
    8000221e:	0e650513          	addi	a0,a0,230 # 80008300 <digits+0x2c0>
    80002222:	ffffe097          	auipc	ra,0xffffe
    80002226:	31c080e7          	jalr	796(ra) # 8000053e <panic>
    panic("sched running");
    8000222a:	00006517          	auipc	a0,0x6
    8000222e:	0e650513          	addi	a0,a0,230 # 80008310 <digits+0x2d0>
    80002232:	ffffe097          	auipc	ra,0xffffe
    80002236:	30c080e7          	jalr	780(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000223a:	00006517          	auipc	a0,0x6
    8000223e:	0e650513          	addi	a0,a0,230 # 80008320 <digits+0x2e0>
    80002242:	ffffe097          	auipc	ra,0xffffe
    80002246:	2fc080e7          	jalr	764(ra) # 8000053e <panic>

000000008000224a <yield>:
{
    8000224a:	1101                	addi	sp,sp,-32
    8000224c:	ec06                	sd	ra,24(sp)
    8000224e:	e822                	sd	s0,16(sp)
    80002250:	e426                	sd	s1,8(sp)
    80002252:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002254:	00000097          	auipc	ra,0x0
    80002258:	820080e7          	jalr	-2016(ra) # 80001a74 <myproc>
    8000225c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	986080e7          	jalr	-1658(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002266:	478d                	li	a5,3
    80002268:	cc9c                	sw	a5,24(s1)
  sched();
    8000226a:	00000097          	auipc	ra,0x0
    8000226e:	f0a080e7          	jalr	-246(ra) # 80002174 <sched>
  release(&p->lock);
    80002272:	8526                	mv	a0,s1
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	a24080e7          	jalr	-1500(ra) # 80000c98 <release>
}
    8000227c:	60e2                	ld	ra,24(sp)
    8000227e:	6442                	ld	s0,16(sp)
    80002280:	64a2                	ld	s1,8(sp)
    80002282:	6105                	addi	sp,sp,32
    80002284:	8082                	ret

0000000080002286 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002286:	7179                	addi	sp,sp,-48
    80002288:	f406                	sd	ra,40(sp)
    8000228a:	f022                	sd	s0,32(sp)
    8000228c:	ec26                	sd	s1,24(sp)
    8000228e:	e84a                	sd	s2,16(sp)
    80002290:	e44e                	sd	s3,8(sp)
    80002292:	1800                	addi	s0,sp,48
    80002294:	89aa                	mv	s3,a0
    80002296:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	7dc080e7          	jalr	2012(ra) # 80001a74 <myproc>
    800022a0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	942080e7          	jalr	-1726(ra) # 80000be4 <acquire>
  release(lk);
    800022aa:	854a                	mv	a0,s2
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	9ec080e7          	jalr	-1556(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800022b4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022b8:	4789                	li	a5,2
    800022ba:	cc9c                	sw	a5,24(s1)

  sched();
    800022bc:	00000097          	auipc	ra,0x0
    800022c0:	eb8080e7          	jalr	-328(ra) # 80002174 <sched>

  // Tidy up.
  p->chan = 0;
    800022c4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022c8:	8526                	mv	a0,s1
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	9ce080e7          	jalr	-1586(ra) # 80000c98 <release>
  acquire(lk);
    800022d2:	854a                	mv	a0,s2
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>
}
    800022dc:	70a2                	ld	ra,40(sp)
    800022de:	7402                	ld	s0,32(sp)
    800022e0:	64e2                	ld	s1,24(sp)
    800022e2:	6942                	ld	s2,16(sp)
    800022e4:	69a2                	ld	s3,8(sp)
    800022e6:	6145                	addi	sp,sp,48
    800022e8:	8082                	ret

00000000800022ea <wait>:
{
    800022ea:	715d                	addi	sp,sp,-80
    800022ec:	e486                	sd	ra,72(sp)
    800022ee:	e0a2                	sd	s0,64(sp)
    800022f0:	fc26                	sd	s1,56(sp)
    800022f2:	f84a                	sd	s2,48(sp)
    800022f4:	f44e                	sd	s3,40(sp)
    800022f6:	f052                	sd	s4,32(sp)
    800022f8:	ec56                	sd	s5,24(sp)
    800022fa:	e85a                	sd	s6,16(sp)
    800022fc:	e45e                	sd	s7,8(sp)
    800022fe:	e062                	sd	s8,0(sp)
    80002300:	0880                	addi	s0,sp,80
    80002302:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	770080e7          	jalr	1904(ra) # 80001a74 <myproc>
    8000230c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000230e:	0000f517          	auipc	a0,0xf
    80002312:	fca50513          	addi	a0,a0,-54 # 800112d8 <wait_lock>
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	8ce080e7          	jalr	-1842(ra) # 80000be4 <acquire>
    havekids = 0;
    8000231e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002320:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002322:	00015997          	auipc	s3,0x15
    80002326:	5ce98993          	addi	s3,s3,1486 # 800178f0 <tickslock>
        havekids = 1;
    8000232a:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000232c:	0000fc17          	auipc	s8,0xf
    80002330:	facc0c13          	addi	s8,s8,-84 # 800112d8 <wait_lock>
    havekids = 0;
    80002334:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002336:	0000f497          	auipc	s1,0xf
    8000233a:	3ba48493          	addi	s1,s1,954 # 800116f0 <proc>
    8000233e:	a0bd                	j	800023ac <wait+0xc2>
          pid = np->pid;
    80002340:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002344:	000b0e63          	beqz	s6,80002360 <wait+0x76>
    80002348:	4691                	li	a3,4
    8000234a:	02c48613          	addi	a2,s1,44
    8000234e:	85da                	mv	a1,s6
    80002350:	05093503          	ld	a0,80(s2)
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	31e080e7          	jalr	798(ra) # 80001672 <copyout>
    8000235c:	02054563          	bltz	a0,80002386 <wait+0x9c>
          freeproc(np);
    80002360:	8526                	mv	a0,s1
    80002362:	00000097          	auipc	ra,0x0
    80002366:	8f0080e7          	jalr	-1808(ra) # 80001c52 <freeproc>
          release(&np->lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	92c080e7          	jalr	-1748(ra) # 80000c98 <release>
          release(&wait_lock);
    80002374:	0000f517          	auipc	a0,0xf
    80002378:	f6450513          	addi	a0,a0,-156 # 800112d8 <wait_lock>
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	91c080e7          	jalr	-1764(ra) # 80000c98 <release>
          return pid;
    80002384:	a09d                	j	800023ea <wait+0x100>
            release(&np->lock);
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
            release(&wait_lock);
    80002390:	0000f517          	auipc	a0,0xf
    80002394:	f4850513          	addi	a0,a0,-184 # 800112d8 <wait_lock>
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	900080e7          	jalr	-1792(ra) # 80000c98 <release>
            return -1;
    800023a0:	59fd                	li	s3,-1
    800023a2:	a0a1                	j	800023ea <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800023a4:	18848493          	addi	s1,s1,392
    800023a8:	03348463          	beq	s1,s3,800023d0 <wait+0xe6>
      if(np->parent == p){
    800023ac:	7c9c                	ld	a5,56(s1)
    800023ae:	ff279be3          	bne	a5,s2,800023a4 <wait+0xba>
        acquire(&np->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	830080e7          	jalr	-2000(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800023bc:	4c9c                	lw	a5,24(s1)
    800023be:	f94781e3          	beq	a5,s4,80002340 <wait+0x56>
        release(&np->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8d4080e7          	jalr	-1836(ra) # 80000c98 <release>
        havekids = 1;
    800023cc:	8756                	mv	a4,s5
    800023ce:	bfd9                	j	800023a4 <wait+0xba>
    if(!havekids || p->killed){
    800023d0:	c701                	beqz	a4,800023d8 <wait+0xee>
    800023d2:	02892783          	lw	a5,40(s2)
    800023d6:	c79d                	beqz	a5,80002404 <wait+0x11a>
      release(&wait_lock);
    800023d8:	0000f517          	auipc	a0,0xf
    800023dc:	f0050513          	addi	a0,a0,-256 # 800112d8 <wait_lock>
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8b8080e7          	jalr	-1864(ra) # 80000c98 <release>
      return -1;
    800023e8:	59fd                	li	s3,-1
}
    800023ea:	854e                	mv	a0,s3
    800023ec:	60a6                	ld	ra,72(sp)
    800023ee:	6406                	ld	s0,64(sp)
    800023f0:	74e2                	ld	s1,56(sp)
    800023f2:	7942                	ld	s2,48(sp)
    800023f4:	79a2                	ld	s3,40(sp)
    800023f6:	7a02                	ld	s4,32(sp)
    800023f8:	6ae2                	ld	s5,24(sp)
    800023fa:	6b42                	ld	s6,16(sp)
    800023fc:	6ba2                	ld	s7,8(sp)
    800023fe:	6c02                	ld	s8,0(sp)
    80002400:	6161                	addi	sp,sp,80
    80002402:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002404:	85e2                	mv	a1,s8
    80002406:	854a                	mv	a0,s2
    80002408:	00000097          	auipc	ra,0x0
    8000240c:	e7e080e7          	jalr	-386(ra) # 80002286 <sleep>
    havekids = 0;
    80002410:	b715                	j	80002334 <wait+0x4a>

0000000080002412 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002412:	7139                	addi	sp,sp,-64
    80002414:	fc06                	sd	ra,56(sp)
    80002416:	f822                	sd	s0,48(sp)
    80002418:	f426                	sd	s1,40(sp)
    8000241a:	f04a                	sd	s2,32(sp)
    8000241c:	ec4e                	sd	s3,24(sp)
    8000241e:	e852                	sd	s4,16(sp)
    80002420:	e456                	sd	s5,8(sp)
    80002422:	0080                	addi	s0,sp,64
    80002424:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002426:	0000f497          	auipc	s1,0xf
    8000242a:	2ca48493          	addi	s1,s1,714 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000242e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002430:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002432:	00015917          	auipc	s2,0x15
    80002436:	4be90913          	addi	s2,s2,1214 # 800178f0 <tickslock>
    8000243a:	a821                	j	80002452 <wakeup+0x40>
        p->state = RUNNABLE;
    8000243c:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	856080e7          	jalr	-1962(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000244a:	18848493          	addi	s1,s1,392
    8000244e:	03248463          	beq	s1,s2,80002476 <wakeup+0x64>
    if(p != myproc()){
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	622080e7          	jalr	1570(ra) # 80001a74 <myproc>
    8000245a:	fea488e3          	beq	s1,a0,8000244a <wakeup+0x38>
      acquire(&p->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	ffffe097          	auipc	ra,0xffffe
    80002464:	784080e7          	jalr	1924(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002468:	4c9c                	lw	a5,24(s1)
    8000246a:	fd379be3          	bne	a5,s3,80002440 <wakeup+0x2e>
    8000246e:	709c                	ld	a5,32(s1)
    80002470:	fd4798e3          	bne	a5,s4,80002440 <wakeup+0x2e>
    80002474:	b7e1                	j	8000243c <wakeup+0x2a>
    }
  }
}
    80002476:	70e2                	ld	ra,56(sp)
    80002478:	7442                	ld	s0,48(sp)
    8000247a:	74a2                	ld	s1,40(sp)
    8000247c:	7902                	ld	s2,32(sp)
    8000247e:	69e2                	ld	s3,24(sp)
    80002480:	6a42                	ld	s4,16(sp)
    80002482:	6aa2                	ld	s5,8(sp)
    80002484:	6121                	addi	sp,sp,64
    80002486:	8082                	ret

0000000080002488 <reparent>:
{
    80002488:	7179                	addi	sp,sp,-48
    8000248a:	f406                	sd	ra,40(sp)
    8000248c:	f022                	sd	s0,32(sp)
    8000248e:	ec26                	sd	s1,24(sp)
    80002490:	e84a                	sd	s2,16(sp)
    80002492:	e44e                	sd	s3,8(sp)
    80002494:	e052                	sd	s4,0(sp)
    80002496:	1800                	addi	s0,sp,48
    80002498:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249a:	0000f497          	auipc	s1,0xf
    8000249e:	25648493          	addi	s1,s1,598 # 800116f0 <proc>
      pp->parent = initproc;
    800024a2:	00007a17          	auipc	s4,0x7
    800024a6:	b86a0a13          	addi	s4,s4,-1146 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024aa:	00015997          	auipc	s3,0x15
    800024ae:	44698993          	addi	s3,s3,1094 # 800178f0 <tickslock>
    800024b2:	a029                	j	800024bc <reparent+0x34>
    800024b4:	18848493          	addi	s1,s1,392
    800024b8:	01348d63          	beq	s1,s3,800024d2 <reparent+0x4a>
    if(pp->parent == p){
    800024bc:	7c9c                	ld	a5,56(s1)
    800024be:	ff279be3          	bne	a5,s2,800024b4 <reparent+0x2c>
      pp->parent = initproc;
    800024c2:	000a3503          	ld	a0,0(s4)
    800024c6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024c8:	00000097          	auipc	ra,0x0
    800024cc:	f4a080e7          	jalr	-182(ra) # 80002412 <wakeup>
    800024d0:	b7d5                	j	800024b4 <reparent+0x2c>
}
    800024d2:	70a2                	ld	ra,40(sp)
    800024d4:	7402                	ld	s0,32(sp)
    800024d6:	64e2                	ld	s1,24(sp)
    800024d8:	6942                	ld	s2,16(sp)
    800024da:	69a2                	ld	s3,8(sp)
    800024dc:	6a02                	ld	s4,0(sp)
    800024de:	6145                	addi	sp,sp,48
    800024e0:	8082                	ret

00000000800024e2 <exit>:
{
    800024e2:	7179                	addi	sp,sp,-48
    800024e4:	f406                	sd	ra,40(sp)
    800024e6:	f022                	sd	s0,32(sp)
    800024e8:	ec26                	sd	s1,24(sp)
    800024ea:	e84a                	sd	s2,16(sp)
    800024ec:	e44e                	sd	s3,8(sp)
    800024ee:	e052                	sd	s4,0(sp)
    800024f0:	1800                	addi	s0,sp,48
    800024f2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	580080e7          	jalr	1408(ra) # 80001a74 <myproc>
    800024fc:	89aa                	mv	s3,a0
  if(p == initproc)
    800024fe:	00007797          	auipc	a5,0x7
    80002502:	b2a7b783          	ld	a5,-1238(a5) # 80009028 <initproc>
    80002506:	0d050493          	addi	s1,a0,208
    8000250a:	15050913          	addi	s2,a0,336
    8000250e:	02a79363          	bne	a5,a0,80002534 <exit+0x52>
    panic("init exiting");
    80002512:	00006517          	auipc	a0,0x6
    80002516:	e2650513          	addi	a0,a0,-474 # 80008338 <digits+0x2f8>
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	024080e7          	jalr	36(ra) # 8000053e <panic>
      fileclose(f);
    80002522:	00002097          	auipc	ra,0x2
    80002526:	234080e7          	jalr	564(ra) # 80004756 <fileclose>
      p->ofile[fd] = 0;
    8000252a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000252e:	04a1                	addi	s1,s1,8
    80002530:	01248563          	beq	s1,s2,8000253a <exit+0x58>
    if(p->ofile[fd]){
    80002534:	6088                	ld	a0,0(s1)
    80002536:	f575                	bnez	a0,80002522 <exit+0x40>
    80002538:	bfdd                	j	8000252e <exit+0x4c>
  begin_op();
    8000253a:	00002097          	auipc	ra,0x2
    8000253e:	d50080e7          	jalr	-688(ra) # 8000428a <begin_op>
  iput(p->cwd);
    80002542:	1509b503          	ld	a0,336(s3)
    80002546:	00001097          	auipc	ra,0x1
    8000254a:	52c080e7          	jalr	1324(ra) # 80003a72 <iput>
  end_op();
    8000254e:	00002097          	auipc	ra,0x2
    80002552:	dbc080e7          	jalr	-580(ra) # 8000430a <end_op>
  p->cwd = 0;
    80002556:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000255a:	0000f497          	auipc	s1,0xf
    8000255e:	d7e48493          	addi	s1,s1,-642 # 800112d8 <wait_lock>
    80002562:	8526                	mv	a0,s1
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	680080e7          	jalr	1664(ra) # 80000be4 <acquire>
  reparent(p);
    8000256c:	854e                	mv	a0,s3
    8000256e:	00000097          	auipc	ra,0x0
    80002572:	f1a080e7          	jalr	-230(ra) # 80002488 <reparent>
  wakeup(p->parent);
    80002576:	0389b503          	ld	a0,56(s3)
    8000257a:	00000097          	auipc	ra,0x0
    8000257e:	e98080e7          	jalr	-360(ra) # 80002412 <wakeup>
  acquire(&p->lock);
    80002582:	854e                	mv	a0,s3
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	660080e7          	jalr	1632(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000258c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002590:	4795                	li	a5,5
    80002592:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002596:	8526                	mv	a0,s1
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	700080e7          	jalr	1792(ra) # 80000c98 <release>
  sched();
    800025a0:	00000097          	auipc	ra,0x0
    800025a4:	bd4080e7          	jalr	-1068(ra) # 80002174 <sched>
  panic("zombie exit");
    800025a8:	00006517          	auipc	a0,0x6
    800025ac:	da050513          	addi	a0,a0,-608 # 80008348 <digits+0x308>
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	f8e080e7          	jalr	-114(ra) # 8000053e <panic>

00000000800025b8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025b8:	7179                	addi	sp,sp,-48
    800025ba:	f406                	sd	ra,40(sp)
    800025bc:	f022                	sd	s0,32(sp)
    800025be:	ec26                	sd	s1,24(sp)
    800025c0:	e84a                	sd	s2,16(sp)
    800025c2:	e44e                	sd	s3,8(sp)
    800025c4:	1800                	addi	s0,sp,48
    800025c6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025c8:	0000f497          	auipc	s1,0xf
    800025cc:	12848493          	addi	s1,s1,296 # 800116f0 <proc>
    800025d0:	00015997          	auipc	s3,0x15
    800025d4:	32098993          	addi	s3,s3,800 # 800178f0 <tickslock>
    acquire(&p->lock);
    800025d8:	8526                	mv	a0,s1
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	60a080e7          	jalr	1546(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025e2:	589c                	lw	a5,48(s1)
    800025e4:	01278d63          	beq	a5,s2,800025fe <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025e8:	8526                	mv	a0,s1
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	6ae080e7          	jalr	1710(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f2:	18848493          	addi	s1,s1,392
    800025f6:	ff3491e3          	bne	s1,s3,800025d8 <kill+0x20>
  }
  return -1;
    800025fa:	557d                	li	a0,-1
    800025fc:	a829                	j	80002616 <kill+0x5e>
      p->killed = 1;
    800025fe:	4785                	li	a5,1
    80002600:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002602:	4c98                	lw	a4,24(s1)
    80002604:	4789                	li	a5,2
    80002606:	00f70f63          	beq	a4,a5,80002624 <kill+0x6c>
      release(&p->lock);
    8000260a:	8526                	mv	a0,s1
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	68c080e7          	jalr	1676(ra) # 80000c98 <release>
      return 0;
    80002614:	4501                	li	a0,0
}
    80002616:	70a2                	ld	ra,40(sp)
    80002618:	7402                	ld	s0,32(sp)
    8000261a:	64e2                	ld	s1,24(sp)
    8000261c:	6942                	ld	s2,16(sp)
    8000261e:	69a2                	ld	s3,8(sp)
    80002620:	6145                	addi	sp,sp,48
    80002622:	8082                	ret
        p->state = RUNNABLE;
    80002624:	478d                	li	a5,3
    80002626:	cc9c                	sw	a5,24(s1)
    80002628:	b7cd                	j	8000260a <kill+0x52>

000000008000262a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000262a:	7179                	addi	sp,sp,-48
    8000262c:	f406                	sd	ra,40(sp)
    8000262e:	f022                	sd	s0,32(sp)
    80002630:	ec26                	sd	s1,24(sp)
    80002632:	e84a                	sd	s2,16(sp)
    80002634:	e44e                	sd	s3,8(sp)
    80002636:	e052                	sd	s4,0(sp)
    80002638:	1800                	addi	s0,sp,48
    8000263a:	84aa                	mv	s1,a0
    8000263c:	892e                	mv	s2,a1
    8000263e:	89b2                	mv	s3,a2
    80002640:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002642:	fffff097          	auipc	ra,0xfffff
    80002646:	432080e7          	jalr	1074(ra) # 80001a74 <myproc>
  if(user_dst){
    8000264a:	c08d                	beqz	s1,8000266c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000264c:	86d2                	mv	a3,s4
    8000264e:	864e                	mv	a2,s3
    80002650:	85ca                	mv	a1,s2
    80002652:	6928                	ld	a0,80(a0)
    80002654:	fffff097          	auipc	ra,0xfffff
    80002658:	01e080e7          	jalr	30(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000265c:	70a2                	ld	ra,40(sp)
    8000265e:	7402                	ld	s0,32(sp)
    80002660:	64e2                	ld	s1,24(sp)
    80002662:	6942                	ld	s2,16(sp)
    80002664:	69a2                	ld	s3,8(sp)
    80002666:	6a02                	ld	s4,0(sp)
    80002668:	6145                	addi	sp,sp,48
    8000266a:	8082                	ret
    memmove((char *)dst, src, len);
    8000266c:	000a061b          	sext.w	a2,s4
    80002670:	85ce                	mv	a1,s3
    80002672:	854a                	mv	a0,s2
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	6cc080e7          	jalr	1740(ra) # 80000d40 <memmove>
    return 0;
    8000267c:	8526                	mv	a0,s1
    8000267e:	bff9                	j	8000265c <either_copyout+0x32>

0000000080002680 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002680:	7179                	addi	sp,sp,-48
    80002682:	f406                	sd	ra,40(sp)
    80002684:	f022                	sd	s0,32(sp)
    80002686:	ec26                	sd	s1,24(sp)
    80002688:	e84a                	sd	s2,16(sp)
    8000268a:	e44e                	sd	s3,8(sp)
    8000268c:	e052                	sd	s4,0(sp)
    8000268e:	1800                	addi	s0,sp,48
    80002690:	892a                	mv	s2,a0
    80002692:	84ae                	mv	s1,a1
    80002694:	89b2                	mv	s3,a2
    80002696:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002698:	fffff097          	auipc	ra,0xfffff
    8000269c:	3dc080e7          	jalr	988(ra) # 80001a74 <myproc>
  if(user_src){
    800026a0:	c08d                	beqz	s1,800026c2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026a2:	86d2                	mv	a3,s4
    800026a4:	864e                	mv	a2,s3
    800026a6:	85ca                	mv	a1,s2
    800026a8:	6928                	ld	a0,80(a0)
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	054080e7          	jalr	84(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026b2:	70a2                	ld	ra,40(sp)
    800026b4:	7402                	ld	s0,32(sp)
    800026b6:	64e2                	ld	s1,24(sp)
    800026b8:	6942                	ld	s2,16(sp)
    800026ba:	69a2                	ld	s3,8(sp)
    800026bc:	6a02                	ld	s4,0(sp)
    800026be:	6145                	addi	sp,sp,48
    800026c0:	8082                	ret
    memmove(dst, (char*)src, len);
    800026c2:	000a061b          	sext.w	a2,s4
    800026c6:	85ce                	mv	a1,s3
    800026c8:	854a                	mv	a0,s2
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	676080e7          	jalr	1654(ra) # 80000d40 <memmove>
    return 0;
    800026d2:	8526                	mv	a0,s1
    800026d4:	bff9                	j	800026b2 <either_copyin+0x32>

00000000800026d6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026d6:	715d                	addi	sp,sp,-80
    800026d8:	e486                	sd	ra,72(sp)
    800026da:	e0a2                	sd	s0,64(sp)
    800026dc:	fc26                	sd	s1,56(sp)
    800026de:	f84a                	sd	s2,48(sp)
    800026e0:	f44e                	sd	s3,40(sp)
    800026e2:	f052                	sd	s4,32(sp)
    800026e4:	ec56                	sd	s5,24(sp)
    800026e6:	e85a                	sd	s6,16(sp)
    800026e8:	e45e                	sd	s7,8(sp)
    800026ea:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026ec:	00006517          	auipc	a0,0x6
    800026f0:	9dc50513          	addi	a0,a0,-1572 # 800080c8 <digits+0x88>
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	e94080e7          	jalr	-364(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026fc:	0000f497          	auipc	s1,0xf
    80002700:	14c48493          	addi	s1,s1,332 # 80011848 <proc+0x158>
    80002704:	00015917          	auipc	s2,0x15
    80002708:	34490913          	addi	s2,s2,836 # 80017a48 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000270c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000270e:	00006997          	auipc	s3,0x6
    80002712:	c4a98993          	addi	s3,s3,-950 # 80008358 <digits+0x318>
    printf("%d %s %s", p->pid, state, p->name);
    80002716:	00006a97          	auipc	s5,0x6
    8000271a:	c4aa8a93          	addi	s5,s5,-950 # 80008360 <digits+0x320>
    printf("\n");
    8000271e:	00006a17          	auipc	s4,0x6
    80002722:	9aaa0a13          	addi	s4,s4,-1622 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002726:	00006b97          	auipc	s7,0x6
    8000272a:	c72b8b93          	addi	s7,s7,-910 # 80008398 <states.1789>
    8000272e:	a00d                	j	80002750 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002730:	ed86a583          	lw	a1,-296(a3)
    80002734:	8556                	mv	a0,s5
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	e52080e7          	jalr	-430(ra) # 80000588 <printf>
    printf("\n");
    8000273e:	8552                	mv	a0,s4
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	e48080e7          	jalr	-440(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002748:	18848493          	addi	s1,s1,392
    8000274c:	03248163          	beq	s1,s2,8000276e <procdump+0x98>
    if(p->state == UNUSED)
    80002750:	86a6                	mv	a3,s1
    80002752:	ec04a783          	lw	a5,-320(s1)
    80002756:	dbed                	beqz	a5,80002748 <procdump+0x72>
      state = "???";
    80002758:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000275a:	fcfb6be3          	bltu	s6,a5,80002730 <procdump+0x5a>
    8000275e:	1782                	slli	a5,a5,0x20
    80002760:	9381                	srli	a5,a5,0x20
    80002762:	078e                	slli	a5,a5,0x3
    80002764:	97de                	add	a5,a5,s7
    80002766:	6390                	ld	a2,0(a5)
    80002768:	f661                	bnez	a2,80002730 <procdump+0x5a>
      state = "???";
    8000276a:	864e                	mv	a2,s3
    8000276c:	b7d1                	j	80002730 <procdump+0x5a>
  }
}
    8000276e:	60a6                	ld	ra,72(sp)
    80002770:	6406                	ld	s0,64(sp)
    80002772:	74e2                	ld	s1,56(sp)
    80002774:	7942                	ld	s2,48(sp)
    80002776:	79a2                	ld	s3,40(sp)
    80002778:	7a02                	ld	s4,32(sp)
    8000277a:	6ae2                	ld	s5,24(sp)
    8000277c:	6b42                	ld	s6,16(sp)
    8000277e:	6ba2                	ld	s7,8(sp)
    80002780:	6161                	addi	sp,sp,80
    80002782:	8082                	ret

0000000080002784 <swtch>:
    80002784:	00153023          	sd	ra,0(a0)
    80002788:	00253423          	sd	sp,8(a0)
    8000278c:	e900                	sd	s0,16(a0)
    8000278e:	ed04                	sd	s1,24(a0)
    80002790:	03253023          	sd	s2,32(a0)
    80002794:	03353423          	sd	s3,40(a0)
    80002798:	03453823          	sd	s4,48(a0)
    8000279c:	03553c23          	sd	s5,56(a0)
    800027a0:	05653023          	sd	s6,64(a0)
    800027a4:	05753423          	sd	s7,72(a0)
    800027a8:	05853823          	sd	s8,80(a0)
    800027ac:	05953c23          	sd	s9,88(a0)
    800027b0:	07a53023          	sd	s10,96(a0)
    800027b4:	07b53423          	sd	s11,104(a0)
    800027b8:	0005b083          	ld	ra,0(a1)
    800027bc:	0085b103          	ld	sp,8(a1)
    800027c0:	6980                	ld	s0,16(a1)
    800027c2:	6d84                	ld	s1,24(a1)
    800027c4:	0205b903          	ld	s2,32(a1)
    800027c8:	0285b983          	ld	s3,40(a1)
    800027cc:	0305ba03          	ld	s4,48(a1)
    800027d0:	0385ba83          	ld	s5,56(a1)
    800027d4:	0405bb03          	ld	s6,64(a1)
    800027d8:	0485bb83          	ld	s7,72(a1)
    800027dc:	0505bc03          	ld	s8,80(a1)
    800027e0:	0585bc83          	ld	s9,88(a1)
    800027e4:	0605bd03          	ld	s10,96(a1)
    800027e8:	0685bd83          	ld	s11,104(a1)
    800027ec:	8082                	ret

00000000800027ee <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027ee:	1141                	addi	sp,sp,-16
    800027f0:	e406                	sd	ra,8(sp)
    800027f2:	e022                	sd	s0,0(sp)
    800027f4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027f6:	00006597          	auipc	a1,0x6
    800027fa:	bd258593          	addi	a1,a1,-1070 # 800083c8 <states.1789+0x30>
    800027fe:	00015517          	auipc	a0,0x15
    80002802:	0f250513          	addi	a0,a0,242 # 800178f0 <tickslock>
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	34e080e7          	jalr	846(ra) # 80000b54 <initlock>
}
    8000280e:	60a2                	ld	ra,8(sp)
    80002810:	6402                	ld	s0,0(sp)
    80002812:	0141                	addi	sp,sp,16
    80002814:	8082                	ret

0000000080002816 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002816:	1141                	addi	sp,sp,-16
    80002818:	e422                	sd	s0,8(sp)
    8000281a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000281c:	00003797          	auipc	a5,0x3
    80002820:	55478793          	addi	a5,a5,1364 # 80005d70 <kernelvec>
    80002824:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002828:	6422                	ld	s0,8(sp)
    8000282a:	0141                	addi	sp,sp,16
    8000282c:	8082                	ret

000000008000282e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000282e:	1141                	addi	sp,sp,-16
    80002830:	e406                	sd	ra,8(sp)
    80002832:	e022                	sd	s0,0(sp)
    80002834:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002836:	fffff097          	auipc	ra,0xfffff
    8000283a:	23e080e7          	jalr	574(ra) # 80001a74 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002842:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002844:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002848:	00004617          	auipc	a2,0x4
    8000284c:	7b860613          	addi	a2,a2,1976 # 80007000 <_trampoline>
    80002850:	00004697          	auipc	a3,0x4
    80002854:	7b068693          	addi	a3,a3,1968 # 80007000 <_trampoline>
    80002858:	8e91                	sub	a3,a3,a2
    8000285a:	040007b7          	lui	a5,0x4000
    8000285e:	17fd                	addi	a5,a5,-1
    80002860:	07b2                	slli	a5,a5,0xc
    80002862:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002864:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002868:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000286a:	180026f3          	csrr	a3,satp
    8000286e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002870:	6d38                	ld	a4,88(a0)
    80002872:	6134                	ld	a3,64(a0)
    80002874:	6585                	lui	a1,0x1
    80002876:	96ae                	add	a3,a3,a1
    80002878:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000287a:	6d38                	ld	a4,88(a0)
    8000287c:	00000697          	auipc	a3,0x0
    80002880:	13868693          	addi	a3,a3,312 # 800029b4 <usertrap>
    80002884:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002886:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002888:	8692                	mv	a3,tp
    8000288a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002890:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002894:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002898:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000289c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000289e:	6f18                	ld	a4,24(a4)
    800028a0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028a4:	692c                	ld	a1,80(a0)
    800028a6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028a8:	00004717          	auipc	a4,0x4
    800028ac:	7e870713          	addi	a4,a4,2024 # 80007090 <userret>
    800028b0:	8f11                	sub	a4,a4,a2
    800028b2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028b4:	577d                	li	a4,-1
    800028b6:	177e                	slli	a4,a4,0x3f
    800028b8:	8dd9                	or	a1,a1,a4
    800028ba:	02000537          	lui	a0,0x2000
    800028be:	157d                	addi	a0,a0,-1
    800028c0:	0536                	slli	a0,a0,0xd
    800028c2:	9782                	jalr	a5
}
    800028c4:	60a2                	ld	ra,8(sp)
    800028c6:	6402                	ld	s0,0(sp)
    800028c8:	0141                	addi	sp,sp,16
    800028ca:	8082                	ret

00000000800028cc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028cc:	1101                	addi	sp,sp,-32
    800028ce:	ec06                	sd	ra,24(sp)
    800028d0:	e822                	sd	s0,16(sp)
    800028d2:	e426                	sd	s1,8(sp)
    800028d4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028d6:	00015497          	auipc	s1,0x15
    800028da:	01a48493          	addi	s1,s1,26 # 800178f0 <tickslock>
    800028de:	8526                	mv	a0,s1
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	304080e7          	jalr	772(ra) # 80000be4 <acquire>
  ticks++;
    800028e8:	00006517          	auipc	a0,0x6
    800028ec:	76850513          	addi	a0,a0,1896 # 80009050 <ticks>
    800028f0:	411c                	lw	a5,0(a0)
    800028f2:	2785                	addiw	a5,a5,1
    800028f4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	b1c080e7          	jalr	-1252(ra) # 80002412 <wakeup>
  release(&tickslock);
    800028fe:	8526                	mv	a0,s1
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	398080e7          	jalr	920(ra) # 80000c98 <release>
}
    80002908:	60e2                	ld	ra,24(sp)
    8000290a:	6442                	ld	s0,16(sp)
    8000290c:	64a2                	ld	s1,8(sp)
    8000290e:	6105                	addi	sp,sp,32
    80002910:	8082                	ret

0000000080002912 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002912:	1101                	addi	sp,sp,-32
    80002914:	ec06                	sd	ra,24(sp)
    80002916:	e822                	sd	s0,16(sp)
    80002918:	e426                	sd	s1,8(sp)
    8000291a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002920:	00074d63          	bltz	a4,8000293a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002924:	57fd                	li	a5,-1
    80002926:	17fe                	slli	a5,a5,0x3f
    80002928:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000292a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000292c:	06f70363          	beq	a4,a5,80002992 <devintr+0x80>
  }
}
    80002930:	60e2                	ld	ra,24(sp)
    80002932:	6442                	ld	s0,16(sp)
    80002934:	64a2                	ld	s1,8(sp)
    80002936:	6105                	addi	sp,sp,32
    80002938:	8082                	ret
     (scause & 0xff) == 9){
    8000293a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000293e:	46a5                	li	a3,9
    80002940:	fed792e3          	bne	a5,a3,80002924 <devintr+0x12>
    int irq = plic_claim();
    80002944:	00003097          	auipc	ra,0x3
    80002948:	534080e7          	jalr	1332(ra) # 80005e78 <plic_claim>
    8000294c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000294e:	47a9                	li	a5,10
    80002950:	02f50763          	beq	a0,a5,8000297e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002954:	4785                	li	a5,1
    80002956:	02f50963          	beq	a0,a5,80002988 <devintr+0x76>
    return 1;
    8000295a:	4505                	li	a0,1
    } else if(irq){
    8000295c:	d8f1                	beqz	s1,80002930 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000295e:	85a6                	mv	a1,s1
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a7050513          	addi	a0,a0,-1424 # 800083d0 <states.1789+0x38>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c20080e7          	jalr	-992(ra) # 80000588 <printf>
      plic_complete(irq);
    80002970:	8526                	mv	a0,s1
    80002972:	00003097          	auipc	ra,0x3
    80002976:	52a080e7          	jalr	1322(ra) # 80005e9c <plic_complete>
    return 1;
    8000297a:	4505                	li	a0,1
    8000297c:	bf55                	j	80002930 <devintr+0x1e>
      uartintr();
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	02a080e7          	jalr	42(ra) # 800009a8 <uartintr>
    80002986:	b7ed                	j	80002970 <devintr+0x5e>
      virtio_disk_intr();
    80002988:	00004097          	auipc	ra,0x4
    8000298c:	9f4080e7          	jalr	-1548(ra) # 8000637c <virtio_disk_intr>
    80002990:	b7c5                	j	80002970 <devintr+0x5e>
    if(cpuid() == 0){
    80002992:	fffff097          	auipc	ra,0xfffff
    80002996:	0b6080e7          	jalr	182(ra) # 80001a48 <cpuid>
    8000299a:	c901                	beqz	a0,800029aa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000299c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029a0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029a2:	14479073          	csrw	sip,a5
    return 2;
    800029a6:	4509                	li	a0,2
    800029a8:	b761                	j	80002930 <devintr+0x1e>
      clockintr();
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	f22080e7          	jalr	-222(ra) # 800028cc <clockintr>
    800029b2:	b7ed                	j	8000299c <devintr+0x8a>

00000000800029b4 <usertrap>:
{
    800029b4:	1101                	addi	sp,sp,-32
    800029b6:	ec06                	sd	ra,24(sp)
    800029b8:	e822                	sd	s0,16(sp)
    800029ba:	e426                	sd	s1,8(sp)
    800029bc:	e04a                	sd	s2,0(sp)
    800029be:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029c4:	1007f793          	andi	a5,a5,256
    800029c8:	e3ad                	bnez	a5,80002a2a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ca:	00003797          	auipc	a5,0x3
    800029ce:	3a678793          	addi	a5,a5,934 # 80005d70 <kernelvec>
    800029d2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029d6:	fffff097          	auipc	ra,0xfffff
    800029da:	09e080e7          	jalr	158(ra) # 80001a74 <myproc>
    800029de:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029e0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e2:	14102773          	csrr	a4,sepc
    800029e6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029ec:	47a1                	li	a5,8
    800029ee:	04f71c63          	bne	a4,a5,80002a46 <usertrap+0x92>
    if(p->killed)
    800029f2:	551c                	lw	a5,40(a0)
    800029f4:	e3b9                	bnez	a5,80002a3a <usertrap+0x86>
    p->trapframe->epc += 4;
    800029f6:	6cb8                	ld	a4,88(s1)
    800029f8:	6f1c                	ld	a5,24(a4)
    800029fa:	0791                	addi	a5,a5,4
    800029fc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a02:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a06:	10079073          	csrw	sstatus,a5
    syscall();
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	2e0080e7          	jalr	736(ra) # 80002cea <syscall>
  if(p->killed)
    80002a12:	549c                	lw	a5,40(s1)
    80002a14:	ebc1                	bnez	a5,80002aa4 <usertrap+0xf0>
  usertrapret();
    80002a16:	00000097          	auipc	ra,0x0
    80002a1a:	e18080e7          	jalr	-488(ra) # 8000282e <usertrapret>
}
    80002a1e:	60e2                	ld	ra,24(sp)
    80002a20:	6442                	ld	s0,16(sp)
    80002a22:	64a2                	ld	s1,8(sp)
    80002a24:	6902                	ld	s2,0(sp)
    80002a26:	6105                	addi	sp,sp,32
    80002a28:	8082                	ret
    panic("usertrap: not from user mode");
    80002a2a:	00006517          	auipc	a0,0x6
    80002a2e:	9c650513          	addi	a0,a0,-1594 # 800083f0 <states.1789+0x58>
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	b0c080e7          	jalr	-1268(ra) # 8000053e <panic>
      exit(-1);
    80002a3a:	557d                	li	a0,-1
    80002a3c:	00000097          	auipc	ra,0x0
    80002a40:	aa6080e7          	jalr	-1370(ra) # 800024e2 <exit>
    80002a44:	bf4d                	j	800029f6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a46:	00000097          	auipc	ra,0x0
    80002a4a:	ecc080e7          	jalr	-308(ra) # 80002912 <devintr>
    80002a4e:	892a                	mv	s2,a0
    80002a50:	c501                	beqz	a0,80002a58 <usertrap+0xa4>
  if(p->killed)
    80002a52:	549c                	lw	a5,40(s1)
    80002a54:	c3a1                	beqz	a5,80002a94 <usertrap+0xe0>
    80002a56:	a815                	j	80002a8a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a58:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a5c:	5890                	lw	a2,48(s1)
    80002a5e:	00006517          	auipc	a0,0x6
    80002a62:	9b250513          	addi	a0,a0,-1614 # 80008410 <states.1789+0x78>
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	b22080e7          	jalr	-1246(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a6e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a72:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a76:	00006517          	auipc	a0,0x6
    80002a7a:	9ca50513          	addi	a0,a0,-1590 # 80008440 <states.1789+0xa8>
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	b0a080e7          	jalr	-1270(ra) # 80000588 <printf>
    p->killed = 1;
    80002a86:	4785                	li	a5,1
    80002a88:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a8a:	557d                	li	a0,-1
    80002a8c:	00000097          	auipc	ra,0x0
    80002a90:	a56080e7          	jalr	-1450(ra) # 800024e2 <exit>
  if(which_dev == 2)
    80002a94:	4789                	li	a5,2
    80002a96:	f8f910e3          	bne	s2,a5,80002a16 <usertrap+0x62>
    yield();
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	7b0080e7          	jalr	1968(ra) # 8000224a <yield>
    80002aa2:	bf95                	j	80002a16 <usertrap+0x62>
  int which_dev = 0;
    80002aa4:	4901                	li	s2,0
    80002aa6:	b7d5                	j	80002a8a <usertrap+0xd6>

0000000080002aa8 <kerneltrap>:
{
    80002aa8:	7179                	addi	sp,sp,-48
    80002aaa:	f406                	sd	ra,40(sp)
    80002aac:	f022                	sd	s0,32(sp)
    80002aae:	ec26                	sd	s1,24(sp)
    80002ab0:	e84a                	sd	s2,16(sp)
    80002ab2:	e44e                	sd	s3,8(sp)
    80002ab4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ab6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aba:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002abe:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ac2:	1004f793          	andi	a5,s1,256
    80002ac6:	cb85                	beqz	a5,80002af6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002acc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ace:	ef85                	bnez	a5,80002b06 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	e42080e7          	jalr	-446(ra) # 80002912 <devintr>
    80002ad8:	cd1d                	beqz	a0,80002b16 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ada:	4789                	li	a5,2
    80002adc:	06f50a63          	beq	a0,a5,80002b50 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ae0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae4:	10049073          	csrw	sstatus,s1
}
    80002ae8:	70a2                	ld	ra,40(sp)
    80002aea:	7402                	ld	s0,32(sp)
    80002aec:	64e2                	ld	s1,24(sp)
    80002aee:	6942                	ld	s2,16(sp)
    80002af0:	69a2                	ld	s3,8(sp)
    80002af2:	6145                	addi	sp,sp,48
    80002af4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002af6:	00006517          	auipc	a0,0x6
    80002afa:	96a50513          	addi	a0,a0,-1686 # 80008460 <states.1789+0xc8>
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a40080e7          	jalr	-1472(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	98250513          	addi	a0,a0,-1662 # 80008488 <states.1789+0xf0>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a30080e7          	jalr	-1488(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b16:	85ce                	mv	a1,s3
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	99050513          	addi	a0,a0,-1648 # 800084a8 <states.1789+0x110>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a68080e7          	jalr	-1432(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b28:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b2c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b30:	00006517          	auipc	a0,0x6
    80002b34:	98850513          	addi	a0,a0,-1656 # 800084b8 <states.1789+0x120>
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	a50080e7          	jalr	-1456(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b40:	00006517          	auipc	a0,0x6
    80002b44:	99050513          	addi	a0,a0,-1648 # 800084d0 <states.1789+0x138>
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	9f6080e7          	jalr	-1546(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b50:	fffff097          	auipc	ra,0xfffff
    80002b54:	f24080e7          	jalr	-220(ra) # 80001a74 <myproc>
    80002b58:	d541                	beqz	a0,80002ae0 <kerneltrap+0x38>
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	f1a080e7          	jalr	-230(ra) # 80001a74 <myproc>
    80002b62:	4d18                	lw	a4,24(a0)
    80002b64:	4791                	li	a5,4
    80002b66:	f6f71de3          	bne	a4,a5,80002ae0 <kerneltrap+0x38>
    yield();
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	6e0080e7          	jalr	1760(ra) # 8000224a <yield>
    80002b72:	b7bd                	j	80002ae0 <kerneltrap+0x38>

0000000080002b74 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b74:	1101                	addi	sp,sp,-32
    80002b76:	ec06                	sd	ra,24(sp)
    80002b78:	e822                	sd	s0,16(sp)
    80002b7a:	e426                	sd	s1,8(sp)
    80002b7c:	1000                	addi	s0,sp,32
    80002b7e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b80:	fffff097          	auipc	ra,0xfffff
    80002b84:	ef4080e7          	jalr	-268(ra) # 80001a74 <myproc>
  switch (n) {
    80002b88:	4795                	li	a5,5
    80002b8a:	0497e163          	bltu	a5,s1,80002bcc <argraw+0x58>
    80002b8e:	048a                	slli	s1,s1,0x2
    80002b90:	00006717          	auipc	a4,0x6
    80002b94:	97870713          	addi	a4,a4,-1672 # 80008508 <states.1789+0x170>
    80002b98:	94ba                	add	s1,s1,a4
    80002b9a:	409c                	lw	a5,0(s1)
    80002b9c:	97ba                	add	a5,a5,a4
    80002b9e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ba0:	6d3c                	ld	a5,88(a0)
    80002ba2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ba4:	60e2                	ld	ra,24(sp)
    80002ba6:	6442                	ld	s0,16(sp)
    80002ba8:	64a2                	ld	s1,8(sp)
    80002baa:	6105                	addi	sp,sp,32
    80002bac:	8082                	ret
    return p->trapframe->a1;
    80002bae:	6d3c                	ld	a5,88(a0)
    80002bb0:	7fa8                	ld	a0,120(a5)
    80002bb2:	bfcd                	j	80002ba4 <argraw+0x30>
    return p->trapframe->a2;
    80002bb4:	6d3c                	ld	a5,88(a0)
    80002bb6:	63c8                	ld	a0,128(a5)
    80002bb8:	b7f5                	j	80002ba4 <argraw+0x30>
    return p->trapframe->a3;
    80002bba:	6d3c                	ld	a5,88(a0)
    80002bbc:	67c8                	ld	a0,136(a5)
    80002bbe:	b7dd                	j	80002ba4 <argraw+0x30>
    return p->trapframe->a4;
    80002bc0:	6d3c                	ld	a5,88(a0)
    80002bc2:	6bc8                	ld	a0,144(a5)
    80002bc4:	b7c5                	j	80002ba4 <argraw+0x30>
    return p->trapframe->a5;
    80002bc6:	6d3c                	ld	a5,88(a0)
    80002bc8:	6fc8                	ld	a0,152(a5)
    80002bca:	bfe9                	j	80002ba4 <argraw+0x30>
  panic("argraw");
    80002bcc:	00006517          	auipc	a0,0x6
    80002bd0:	91450513          	addi	a0,a0,-1772 # 800084e0 <states.1789+0x148>
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	96a080e7          	jalr	-1686(ra) # 8000053e <panic>

0000000080002bdc <fetchaddr>:
{
    80002bdc:	1101                	addi	sp,sp,-32
    80002bde:	ec06                	sd	ra,24(sp)
    80002be0:	e822                	sd	s0,16(sp)
    80002be2:	e426                	sd	s1,8(sp)
    80002be4:	e04a                	sd	s2,0(sp)
    80002be6:	1000                	addi	s0,sp,32
    80002be8:	84aa                	mv	s1,a0
    80002bea:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bec:	fffff097          	auipc	ra,0xfffff
    80002bf0:	e88080e7          	jalr	-376(ra) # 80001a74 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bf4:	653c                	ld	a5,72(a0)
    80002bf6:	02f4f863          	bgeu	s1,a5,80002c26 <fetchaddr+0x4a>
    80002bfa:	00848713          	addi	a4,s1,8
    80002bfe:	02e7e663          	bltu	a5,a4,80002c2a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c02:	46a1                	li	a3,8
    80002c04:	8626                	mv	a2,s1
    80002c06:	85ca                	mv	a1,s2
    80002c08:	6928                	ld	a0,80(a0)
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	af4080e7          	jalr	-1292(ra) # 800016fe <copyin>
    80002c12:	00a03533          	snez	a0,a0
    80002c16:	40a00533          	neg	a0,a0
}
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	64a2                	ld	s1,8(sp)
    80002c20:	6902                	ld	s2,0(sp)
    80002c22:	6105                	addi	sp,sp,32
    80002c24:	8082                	ret
    return -1;
    80002c26:	557d                	li	a0,-1
    80002c28:	bfcd                	j	80002c1a <fetchaddr+0x3e>
    80002c2a:	557d                	li	a0,-1
    80002c2c:	b7fd                	j	80002c1a <fetchaddr+0x3e>

0000000080002c2e <fetchstr>:
{
    80002c2e:	7179                	addi	sp,sp,-48
    80002c30:	f406                	sd	ra,40(sp)
    80002c32:	f022                	sd	s0,32(sp)
    80002c34:	ec26                	sd	s1,24(sp)
    80002c36:	e84a                	sd	s2,16(sp)
    80002c38:	e44e                	sd	s3,8(sp)
    80002c3a:	1800                	addi	s0,sp,48
    80002c3c:	892a                	mv	s2,a0
    80002c3e:	84ae                	mv	s1,a1
    80002c40:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	e32080e7          	jalr	-462(ra) # 80001a74 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c4a:	86ce                	mv	a3,s3
    80002c4c:	864a                	mv	a2,s2
    80002c4e:	85a6                	mv	a1,s1
    80002c50:	6928                	ld	a0,80(a0)
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	b38080e7          	jalr	-1224(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c5a:	00054763          	bltz	a0,80002c68 <fetchstr+0x3a>
  return strlen(buf);
    80002c5e:	8526                	mv	a0,s1
    80002c60:	ffffe097          	auipc	ra,0xffffe
    80002c64:	204080e7          	jalr	516(ra) # 80000e64 <strlen>
}
    80002c68:	70a2                	ld	ra,40(sp)
    80002c6a:	7402                	ld	s0,32(sp)
    80002c6c:	64e2                	ld	s1,24(sp)
    80002c6e:	6942                	ld	s2,16(sp)
    80002c70:	69a2                	ld	s3,8(sp)
    80002c72:	6145                	addi	sp,sp,48
    80002c74:	8082                	ret

0000000080002c76 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c76:	1101                	addi	sp,sp,-32
    80002c78:	ec06                	sd	ra,24(sp)
    80002c7a:	e822                	sd	s0,16(sp)
    80002c7c:	e426                	sd	s1,8(sp)
    80002c7e:	1000                	addi	s0,sp,32
    80002c80:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c82:	00000097          	auipc	ra,0x0
    80002c86:	ef2080e7          	jalr	-270(ra) # 80002b74 <argraw>
    80002c8a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c8c:	4501                	li	a0,0
    80002c8e:	60e2                	ld	ra,24(sp)
    80002c90:	6442                	ld	s0,16(sp)
    80002c92:	64a2                	ld	s1,8(sp)
    80002c94:	6105                	addi	sp,sp,32
    80002c96:	8082                	ret

0000000080002c98 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c98:	1101                	addi	sp,sp,-32
    80002c9a:	ec06                	sd	ra,24(sp)
    80002c9c:	e822                	sd	s0,16(sp)
    80002c9e:	e426                	sd	s1,8(sp)
    80002ca0:	1000                	addi	s0,sp,32
    80002ca2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ca4:	00000097          	auipc	ra,0x0
    80002ca8:	ed0080e7          	jalr	-304(ra) # 80002b74 <argraw>
    80002cac:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cae:	4501                	li	a0,0
    80002cb0:	60e2                	ld	ra,24(sp)
    80002cb2:	6442                	ld	s0,16(sp)
    80002cb4:	64a2                	ld	s1,8(sp)
    80002cb6:	6105                	addi	sp,sp,32
    80002cb8:	8082                	ret

0000000080002cba <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cba:	1101                	addi	sp,sp,-32
    80002cbc:	ec06                	sd	ra,24(sp)
    80002cbe:	e822                	sd	s0,16(sp)
    80002cc0:	e426                	sd	s1,8(sp)
    80002cc2:	e04a                	sd	s2,0(sp)
    80002cc4:	1000                	addi	s0,sp,32
    80002cc6:	84ae                	mv	s1,a1
    80002cc8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cca:	00000097          	auipc	ra,0x0
    80002cce:	eaa080e7          	jalr	-342(ra) # 80002b74 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cd2:	864a                	mv	a2,s2
    80002cd4:	85a6                	mv	a1,s1
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	f58080e7          	jalr	-168(ra) # 80002c2e <fetchstr>
}
    80002cde:	60e2                	ld	ra,24(sp)
    80002ce0:	6442                	ld	s0,16(sp)
    80002ce2:	64a2                	ld	s1,8(sp)
    80002ce4:	6902                	ld	s2,0(sp)
    80002ce6:	6105                	addi	sp,sp,32
    80002ce8:	8082                	ret

0000000080002cea <syscall>:
[SYS_sched_statistics] sys_sched_statistics,
};

void
syscall(void)
{
    80002cea:	1101                	addi	sp,sp,-32
    80002cec:	ec06                	sd	ra,24(sp)
    80002cee:	e822                	sd	s0,16(sp)
    80002cf0:	e426                	sd	s1,8(sp)
    80002cf2:	e04a                	sd	s2,0(sp)
    80002cf4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	d7e080e7          	jalr	-642(ra) # 80001a74 <myproc>
    80002cfe:	84aa                	mv	s1,a0
  p->syscallCount++;
    80002d00:	16853783          	ld	a5,360(a0)
    80002d04:	0785                	addi	a5,a5,1
    80002d06:	16f53423          	sd	a5,360(a0)

  num = p->trapframe->a7;
    80002d0a:	05853903          	ld	s2,88(a0)
    80002d0e:	0a893783          	ld	a5,168(s2)
    80002d12:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d16:	37fd                	addiw	a5,a5,-1
    80002d18:	475d                	li	a4,23
    80002d1a:	00f76f63          	bltu	a4,a5,80002d38 <syscall+0x4e>
    80002d1e:	00369713          	slli	a4,a3,0x3
    80002d22:	00005797          	auipc	a5,0x5
    80002d26:	7fe78793          	addi	a5,a5,2046 # 80008520 <syscalls>
    80002d2a:	97ba                	add	a5,a5,a4
    80002d2c:	639c                	ld	a5,0(a5)
    80002d2e:	c789                	beqz	a5,80002d38 <syscall+0x4e>
    p->trapframe->a0 = syscalls[num]();
    80002d30:	9782                	jalr	a5
    80002d32:	06a93823          	sd	a0,112(s2)
    80002d36:	a839                	j	80002d54 <syscall+0x6a>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d38:	15848613          	addi	a2,s1,344
    80002d3c:	588c                	lw	a1,48(s1)
    80002d3e:	00005517          	auipc	a0,0x5
    80002d42:	7aa50513          	addi	a0,a0,1962 # 800084e8 <states.1789+0x150>
    80002d46:	ffffe097          	auipc	ra,0xffffe
    80002d4a:	842080e7          	jalr	-1982(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d4e:	6cbc                	ld	a5,88(s1)
    80002d50:	577d                	li	a4,-1
    80002d52:	fbb8                	sd	a4,112(a5)
  }
}
    80002d54:	60e2                	ld	ra,24(sp)
    80002d56:	6442                	ld	s0,16(sp)
    80002d58:	64a2                	ld	s1,8(sp)
    80002d5a:	6902                	ld	s2,0(sp)
    80002d5c:	6105                	addi	sp,sp,32
    80002d5e:	8082                	ret

0000000080002d60 <sys_sched_statistics>:
#include "spinlock.h"
#include "proc.h"


uint64 sys_sched_statistics(void)
{
    80002d60:	1141                	addi	sp,sp,-16
    80002d62:	e406                	sd	ra,8(sp)
    80002d64:	e022                	sd	s0,0(sp)
    80002d66:	0800                	addi	s0,sp,16
  sched_statistics();
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	3c6080e7          	jalr	966(ra) # 8000212e <sched_statistics>
  return 0;
}
    80002d70:	4501                	li	a0,0
    80002d72:	60a2                	ld	ra,8(sp)
    80002d74:	6402                	ld	s0,0(sp)
    80002d76:	0141                	addi	sp,sp,16
    80002d78:	8082                	ret

0000000080002d7a <sys_set_tickets>:

// for lottery scheduling
uint64 sys_set_tickets(void)
{
    80002d7a:	1101                	addi	sp,sp,-32
    80002d7c:	ec06                	sd	ra,24(sp)
    80002d7e:	e822                	sd	s0,16(sp)
    80002d80:	1000                	addi	s0,sp,32
  printf("Calling sys_set_tickets function in sysproc.c\n");
    80002d82:	00006517          	auipc	a0,0x6
    80002d86:	86650513          	addi	a0,a0,-1946 # 800085e8 <syscalls+0xc8>
    80002d8a:	ffffd097          	auipc	ra,0xffffd
    80002d8e:	7fe080e7          	jalr	2046(ra) # 80000588 <printf>
	int numTickets;
	if (argint(0, &numTickets) < 0)
    80002d92:	fec40593          	addi	a1,s0,-20
    80002d96:	4501                	li	a0,0
    80002d98:	00000097          	auipc	ra,0x0
    80002d9c:	ede080e7          	jalr	-290(ra) # 80002c76 <argint>
		return -1;
    80002da0:	57fd                	li	a5,-1
	if (argint(0, &numTickets) < 0)
    80002da2:	00054963          	bltz	a0,80002db4 <sys_set_tickets+0x3a>
	set_tickets(numTickets);
    80002da6:	fec42503          	lw	a0,-20(s0)
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	34a080e7          	jalr	842(ra) # 800020f4 <set_tickets>
	return 0;
    80002db2:	4781                	li	a5,0
}
    80002db4:	853e                	mv	a0,a5
    80002db6:	60e2                	ld	ra,24(sp)
    80002db8:	6442                	ld	s0,16(sp)
    80002dba:	6105                	addi	sp,sp,32
    80002dbc:	8082                	ret

0000000080002dbe <sys_info>:

uint64 sys_info(void){
    80002dbe:	1101                	addi	sp,sp,-32
    80002dc0:	ec06                	sd	ra,24(sp)
    80002dc2:	e822                	sd	s0,16(sp)
    80002dc4:	1000                	addi	s0,sp,32
	int n;
	argint(0,&n);
    80002dc6:	fec40593          	addi	a1,s0,-20
    80002dca:	4501                	li	a0,0
    80002dcc:	00000097          	auipc	ra,0x0
    80002dd0:	eaa080e7          	jalr	-342(ra) # 80002c76 <argint>
	printf("The value of n is %d\n", n);
    80002dd4:	fec42583          	lw	a1,-20(s0)
    80002dd8:	00006517          	auipc	a0,0x6
    80002ddc:	84050513          	addi	a0,a0,-1984 # 80008618 <syscalls+0xf8>
    80002de0:	ffffd097          	auipc	ra,0xffffd
    80002de4:	7a8080e7          	jalr	1960(ra) # 80000588 <printf>
	if (n == 1){
    80002de8:	fec42783          	lw	a5,-20(s0)
    80002dec:	4705                	li	a4,1
    80002dee:	00e78d63          	beq	a5,a4,80002e08 <sys_info+0x4a>
		process_count_print();
	}
	else if (n == 2){
    80002df2:	4709                	li	a4,2
    80002df4:	00e78f63          	beq	a5,a4,80002e12 <sys_info+0x54>
		syscall_count_print();
	}
  else if (n == 3){
    80002df8:	470d                	li	a4,3
    80002dfa:	02e78163          	beq	a5,a4,80002e1c <sys_info+0x5e>
    mem_pages_count_print();
  }
	return 0;
}
    80002dfe:	4501                	li	a0,0
    80002e00:	60e2                	ld	ra,24(sp)
    80002e02:	6442                	ld	s0,16(sp)
    80002e04:	6105                	addi	sp,sp,32
    80002e06:	8082                	ret
		process_count_print();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	b1a080e7          	jalr	-1254(ra) # 80001922 <process_count_print>
    80002e10:	b7fd                	j	80002dfe <sys_info+0x40>
		syscall_count_print();
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	c9a080e7          	jalr	-870(ra) # 80001aac <syscall_count_print>
    80002e1a:	b7d5                	j	80002dfe <sys_info+0x40>
    mem_pages_count_print();
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	b4a080e7          	jalr	-1206(ra) # 80001966 <mem_pages_count_print>
    80002e24:	bfe9                	j	80002dfe <sys_info+0x40>

0000000080002e26 <sys_exit>:

uint64
sys_exit(void)
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e2e:	fec40593          	addi	a1,s0,-20
    80002e32:	4501                	li	a0,0
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	e42080e7          	jalr	-446(ra) # 80002c76 <argint>
    return -1;
    80002e3c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e3e:	00054963          	bltz	a0,80002e50 <sys_exit+0x2a>
  exit(n);
    80002e42:	fec42503          	lw	a0,-20(s0)
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	69c080e7          	jalr	1692(ra) # 800024e2 <exit>
  return 0;  // not reached
    80002e4e:	4781                	li	a5,0
}
    80002e50:	853e                	mv	a0,a5
    80002e52:	60e2                	ld	ra,24(sp)
    80002e54:	6442                	ld	s0,16(sp)
    80002e56:	6105                	addi	sp,sp,32
    80002e58:	8082                	ret

0000000080002e5a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e5a:	1141                	addi	sp,sp,-16
    80002e5c:	e406                	sd	ra,8(sp)
    80002e5e:	e022                	sd	s0,0(sp)
    80002e60:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	c12080e7          	jalr	-1006(ra) # 80001a74 <myproc>
}
    80002e6a:	5908                	lw	a0,48(a0)
    80002e6c:	60a2                	ld	ra,8(sp)
    80002e6e:	6402                	ld	s0,0(sp)
    80002e70:	0141                	addi	sp,sp,16
    80002e72:	8082                	ret

0000000080002e74 <sys_fork>:

uint64
sys_fork(void)
{
    80002e74:	1141                	addi	sp,sp,-16
    80002e76:	e406                	sd	ra,8(sp)
    80002e78:	e022                	sd	s0,0(sp)
    80002e7a:	0800                	addi	s0,sp,16
  return fork();
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	012080e7          	jalr	18(ra) # 80001e8e <fork>
}
    80002e84:	60a2                	ld	ra,8(sp)
    80002e86:	6402                	ld	s0,0(sp)
    80002e88:	0141                	addi	sp,sp,16
    80002e8a:	8082                	ret

0000000080002e8c <sys_wait>:

uint64
sys_wait(void)
{
    80002e8c:	1101                	addi	sp,sp,-32
    80002e8e:	ec06                	sd	ra,24(sp)
    80002e90:	e822                	sd	s0,16(sp)
    80002e92:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e94:	fe840593          	addi	a1,s0,-24
    80002e98:	4501                	li	a0,0
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	dfe080e7          	jalr	-514(ra) # 80002c98 <argaddr>
    80002ea2:	87aa                	mv	a5,a0
    return -1;
    80002ea4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ea6:	0007c863          	bltz	a5,80002eb6 <sys_wait+0x2a>
  return wait(p);
    80002eaa:	fe843503          	ld	a0,-24(s0)
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	43c080e7          	jalr	1084(ra) # 800022ea <wait>
}
    80002eb6:	60e2                	ld	ra,24(sp)
    80002eb8:	6442                	ld	s0,16(sp)
    80002eba:	6105                	addi	sp,sp,32
    80002ebc:	8082                	ret

0000000080002ebe <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ebe:	7179                	addi	sp,sp,-48
    80002ec0:	f406                	sd	ra,40(sp)
    80002ec2:	f022                	sd	s0,32(sp)
    80002ec4:	ec26                	sd	s1,24(sp)
    80002ec6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ec8:	fdc40593          	addi	a1,s0,-36
    80002ecc:	4501                	li	a0,0
    80002ece:	00000097          	auipc	ra,0x0
    80002ed2:	da8080e7          	jalr	-600(ra) # 80002c76 <argint>
    80002ed6:	87aa                	mv	a5,a0
    return -1;
    80002ed8:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002eda:	0207c063          	bltz	a5,80002efa <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	b96080e7          	jalr	-1130(ra) # 80001a74 <myproc>
    80002ee6:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ee8:	fdc42503          	lw	a0,-36(s0)
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	f2e080e7          	jalr	-210(ra) # 80001e1a <growproc>
    80002ef4:	00054863          	bltz	a0,80002f04 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ef8:	8526                	mv	a0,s1
}
    80002efa:	70a2                	ld	ra,40(sp)
    80002efc:	7402                	ld	s0,32(sp)
    80002efe:	64e2                	ld	s1,24(sp)
    80002f00:	6145                	addi	sp,sp,48
    80002f02:	8082                	ret
    return -1;
    80002f04:	557d                	li	a0,-1
    80002f06:	bfd5                	j	80002efa <sys_sbrk+0x3c>

0000000080002f08 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f08:	7139                	addi	sp,sp,-64
    80002f0a:	fc06                	sd	ra,56(sp)
    80002f0c:	f822                	sd	s0,48(sp)
    80002f0e:	f426                	sd	s1,40(sp)
    80002f10:	f04a                	sd	s2,32(sp)
    80002f12:	ec4e                	sd	s3,24(sp)
    80002f14:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f16:	fcc40593          	addi	a1,s0,-52
    80002f1a:	4501                	li	a0,0
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	d5a080e7          	jalr	-678(ra) # 80002c76 <argint>
    return -1;
    80002f24:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f26:	06054563          	bltz	a0,80002f90 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f2a:	00015517          	auipc	a0,0x15
    80002f2e:	9c650513          	addi	a0,a0,-1594 # 800178f0 <tickslock>
    80002f32:	ffffe097          	auipc	ra,0xffffe
    80002f36:	cb2080e7          	jalr	-846(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f3a:	00006917          	auipc	s2,0x6
    80002f3e:	11692903          	lw	s2,278(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80002f42:	fcc42783          	lw	a5,-52(s0)
    80002f46:	cf85                	beqz	a5,80002f7e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f48:	00015997          	auipc	s3,0x15
    80002f4c:	9a898993          	addi	s3,s3,-1624 # 800178f0 <tickslock>
    80002f50:	00006497          	auipc	s1,0x6
    80002f54:	10048493          	addi	s1,s1,256 # 80009050 <ticks>
    if(myproc()->killed){
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	b1c080e7          	jalr	-1252(ra) # 80001a74 <myproc>
    80002f60:	551c                	lw	a5,40(a0)
    80002f62:	ef9d                	bnez	a5,80002fa0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f64:	85ce                	mv	a1,s3
    80002f66:	8526                	mv	a0,s1
    80002f68:	fffff097          	auipc	ra,0xfffff
    80002f6c:	31e080e7          	jalr	798(ra) # 80002286 <sleep>
  while(ticks - ticks0 < n){
    80002f70:	409c                	lw	a5,0(s1)
    80002f72:	412787bb          	subw	a5,a5,s2
    80002f76:	fcc42703          	lw	a4,-52(s0)
    80002f7a:	fce7efe3          	bltu	a5,a4,80002f58 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f7e:	00015517          	auipc	a0,0x15
    80002f82:	97250513          	addi	a0,a0,-1678 # 800178f0 <tickslock>
    80002f86:	ffffe097          	auipc	ra,0xffffe
    80002f8a:	d12080e7          	jalr	-750(ra) # 80000c98 <release>
  return 0;
    80002f8e:	4781                	li	a5,0
}
    80002f90:	853e                	mv	a0,a5
    80002f92:	70e2                	ld	ra,56(sp)
    80002f94:	7442                	ld	s0,48(sp)
    80002f96:	74a2                	ld	s1,40(sp)
    80002f98:	7902                	ld	s2,32(sp)
    80002f9a:	69e2                	ld	s3,24(sp)
    80002f9c:	6121                	addi	sp,sp,64
    80002f9e:	8082                	ret
      release(&tickslock);
    80002fa0:	00015517          	auipc	a0,0x15
    80002fa4:	95050513          	addi	a0,a0,-1712 # 800178f0 <tickslock>
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	cf0080e7          	jalr	-784(ra) # 80000c98 <release>
      return -1;
    80002fb0:	57fd                	li	a5,-1
    80002fb2:	bff9                	j	80002f90 <sys_sleep+0x88>

0000000080002fb4 <sys_kill>:

uint64
sys_kill(void)
{
    80002fb4:	1101                	addi	sp,sp,-32
    80002fb6:	ec06                	sd	ra,24(sp)
    80002fb8:	e822                	sd	s0,16(sp)
    80002fba:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fbc:	fec40593          	addi	a1,s0,-20
    80002fc0:	4501                	li	a0,0
    80002fc2:	00000097          	auipc	ra,0x0
    80002fc6:	cb4080e7          	jalr	-844(ra) # 80002c76 <argint>
    80002fca:	87aa                	mv	a5,a0
    return -1;
    80002fcc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fce:	0007c863          	bltz	a5,80002fde <sys_kill+0x2a>
  return kill(pid);
    80002fd2:	fec42503          	lw	a0,-20(s0)
    80002fd6:	fffff097          	auipc	ra,0xfffff
    80002fda:	5e2080e7          	jalr	1506(ra) # 800025b8 <kill>
}
    80002fde:	60e2                	ld	ra,24(sp)
    80002fe0:	6442                	ld	s0,16(sp)
    80002fe2:	6105                	addi	sp,sp,32
    80002fe4:	8082                	ret

0000000080002fe6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fe6:	1101                	addi	sp,sp,-32
    80002fe8:	ec06                	sd	ra,24(sp)
    80002fea:	e822                	sd	s0,16(sp)
    80002fec:	e426                	sd	s1,8(sp)
    80002fee:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ff0:	00015517          	auipc	a0,0x15
    80002ff4:	90050513          	addi	a0,a0,-1792 # 800178f0 <tickslock>
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	bec080e7          	jalr	-1044(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003000:	00006497          	auipc	s1,0x6
    80003004:	0504a483          	lw	s1,80(s1) # 80009050 <ticks>
  release(&tickslock);
    80003008:	00015517          	auipc	a0,0x15
    8000300c:	8e850513          	addi	a0,a0,-1816 # 800178f0 <tickslock>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	c88080e7          	jalr	-888(ra) # 80000c98 <release>
  return xticks;
}
    80003018:	02049513          	slli	a0,s1,0x20
    8000301c:	9101                	srli	a0,a0,0x20
    8000301e:	60e2                	ld	ra,24(sp)
    80003020:	6442                	ld	s0,16(sp)
    80003022:	64a2                	ld	s1,8(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret

0000000080003028 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003028:	7179                	addi	sp,sp,-48
    8000302a:	f406                	sd	ra,40(sp)
    8000302c:	f022                	sd	s0,32(sp)
    8000302e:	ec26                	sd	s1,24(sp)
    80003030:	e84a                	sd	s2,16(sp)
    80003032:	e44e                	sd	s3,8(sp)
    80003034:	e052                	sd	s4,0(sp)
    80003036:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003038:	00005597          	auipc	a1,0x5
    8000303c:	5f858593          	addi	a1,a1,1528 # 80008630 <syscalls+0x110>
    80003040:	00015517          	auipc	a0,0x15
    80003044:	8c850513          	addi	a0,a0,-1848 # 80017908 <bcache>
    80003048:	ffffe097          	auipc	ra,0xffffe
    8000304c:	b0c080e7          	jalr	-1268(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003050:	0001d797          	auipc	a5,0x1d
    80003054:	8b878793          	addi	a5,a5,-1864 # 8001f908 <bcache+0x8000>
    80003058:	0001d717          	auipc	a4,0x1d
    8000305c:	b1870713          	addi	a4,a4,-1256 # 8001fb70 <bcache+0x8268>
    80003060:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003064:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003068:	00015497          	auipc	s1,0x15
    8000306c:	8b848493          	addi	s1,s1,-1864 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    80003070:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003072:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003074:	00005a17          	auipc	s4,0x5
    80003078:	5c4a0a13          	addi	s4,s4,1476 # 80008638 <syscalls+0x118>
    b->next = bcache.head.next;
    8000307c:	2b893783          	ld	a5,696(s2)
    80003080:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003082:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003086:	85d2                	mv	a1,s4
    80003088:	01048513          	addi	a0,s1,16
    8000308c:	00001097          	auipc	ra,0x1
    80003090:	4bc080e7          	jalr	1212(ra) # 80004548 <initsleeplock>
    bcache.head.next->prev = b;
    80003094:	2b893783          	ld	a5,696(s2)
    80003098:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000309a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000309e:	45848493          	addi	s1,s1,1112
    800030a2:	fd349de3          	bne	s1,s3,8000307c <binit+0x54>
  }
}
    800030a6:	70a2                	ld	ra,40(sp)
    800030a8:	7402                	ld	s0,32(sp)
    800030aa:	64e2                	ld	s1,24(sp)
    800030ac:	6942                	ld	s2,16(sp)
    800030ae:	69a2                	ld	s3,8(sp)
    800030b0:	6a02                	ld	s4,0(sp)
    800030b2:	6145                	addi	sp,sp,48
    800030b4:	8082                	ret

00000000800030b6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030b6:	7179                	addi	sp,sp,-48
    800030b8:	f406                	sd	ra,40(sp)
    800030ba:	f022                	sd	s0,32(sp)
    800030bc:	ec26                	sd	s1,24(sp)
    800030be:	e84a                	sd	s2,16(sp)
    800030c0:	e44e                	sd	s3,8(sp)
    800030c2:	1800                	addi	s0,sp,48
    800030c4:	89aa                	mv	s3,a0
    800030c6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030c8:	00015517          	auipc	a0,0x15
    800030cc:	84050513          	addi	a0,a0,-1984 # 80017908 <bcache>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	b14080e7          	jalr	-1260(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030d8:	0001d497          	auipc	s1,0x1d
    800030dc:	ae84b483          	ld	s1,-1304(s1) # 8001fbc0 <bcache+0x82b8>
    800030e0:	0001d797          	auipc	a5,0x1d
    800030e4:	a9078793          	addi	a5,a5,-1392 # 8001fb70 <bcache+0x8268>
    800030e8:	02f48f63          	beq	s1,a5,80003126 <bread+0x70>
    800030ec:	873e                	mv	a4,a5
    800030ee:	a021                	j	800030f6 <bread+0x40>
    800030f0:	68a4                	ld	s1,80(s1)
    800030f2:	02e48a63          	beq	s1,a4,80003126 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030f6:	449c                	lw	a5,8(s1)
    800030f8:	ff379ce3          	bne	a5,s3,800030f0 <bread+0x3a>
    800030fc:	44dc                	lw	a5,12(s1)
    800030fe:	ff2799e3          	bne	a5,s2,800030f0 <bread+0x3a>
      b->refcnt++;
    80003102:	40bc                	lw	a5,64(s1)
    80003104:	2785                	addiw	a5,a5,1
    80003106:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003108:	00015517          	auipc	a0,0x15
    8000310c:	80050513          	addi	a0,a0,-2048 # 80017908 <bcache>
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	b88080e7          	jalr	-1144(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003118:	01048513          	addi	a0,s1,16
    8000311c:	00001097          	auipc	ra,0x1
    80003120:	466080e7          	jalr	1126(ra) # 80004582 <acquiresleep>
      return b;
    80003124:	a8b9                	j	80003182 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003126:	0001d497          	auipc	s1,0x1d
    8000312a:	a924b483          	ld	s1,-1390(s1) # 8001fbb8 <bcache+0x82b0>
    8000312e:	0001d797          	auipc	a5,0x1d
    80003132:	a4278793          	addi	a5,a5,-1470 # 8001fb70 <bcache+0x8268>
    80003136:	00f48863          	beq	s1,a5,80003146 <bread+0x90>
    8000313a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000313c:	40bc                	lw	a5,64(s1)
    8000313e:	cf81                	beqz	a5,80003156 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003140:	64a4                	ld	s1,72(s1)
    80003142:	fee49de3          	bne	s1,a4,8000313c <bread+0x86>
  panic("bget: no buffers");
    80003146:	00005517          	auipc	a0,0x5
    8000314a:	4fa50513          	addi	a0,a0,1274 # 80008640 <syscalls+0x120>
    8000314e:	ffffd097          	auipc	ra,0xffffd
    80003152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>
      b->dev = dev;
    80003156:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000315a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000315e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003162:	4785                	li	a5,1
    80003164:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003166:	00014517          	auipc	a0,0x14
    8000316a:	7a250513          	addi	a0,a0,1954 # 80017908 <bcache>
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	b2a080e7          	jalr	-1238(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003176:	01048513          	addi	a0,s1,16
    8000317a:	00001097          	auipc	ra,0x1
    8000317e:	408080e7          	jalr	1032(ra) # 80004582 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003182:	409c                	lw	a5,0(s1)
    80003184:	cb89                	beqz	a5,80003196 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003186:	8526                	mv	a0,s1
    80003188:	70a2                	ld	ra,40(sp)
    8000318a:	7402                	ld	s0,32(sp)
    8000318c:	64e2                	ld	s1,24(sp)
    8000318e:	6942                	ld	s2,16(sp)
    80003190:	69a2                	ld	s3,8(sp)
    80003192:	6145                	addi	sp,sp,48
    80003194:	8082                	ret
    virtio_disk_rw(b, 0);
    80003196:	4581                	li	a1,0
    80003198:	8526                	mv	a0,s1
    8000319a:	00003097          	auipc	ra,0x3
    8000319e:	f0c080e7          	jalr	-244(ra) # 800060a6 <virtio_disk_rw>
    b->valid = 1;
    800031a2:	4785                	li	a5,1
    800031a4:	c09c                	sw	a5,0(s1)
  return b;
    800031a6:	b7c5                	j	80003186 <bread+0xd0>

00000000800031a8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031a8:	1101                	addi	sp,sp,-32
    800031aa:	ec06                	sd	ra,24(sp)
    800031ac:	e822                	sd	s0,16(sp)
    800031ae:	e426                	sd	s1,8(sp)
    800031b0:	1000                	addi	s0,sp,32
    800031b2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031b4:	0541                	addi	a0,a0,16
    800031b6:	00001097          	auipc	ra,0x1
    800031ba:	466080e7          	jalr	1126(ra) # 8000461c <holdingsleep>
    800031be:	cd01                	beqz	a0,800031d6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031c0:	4585                	li	a1,1
    800031c2:	8526                	mv	a0,s1
    800031c4:	00003097          	auipc	ra,0x3
    800031c8:	ee2080e7          	jalr	-286(ra) # 800060a6 <virtio_disk_rw>
}
    800031cc:	60e2                	ld	ra,24(sp)
    800031ce:	6442                	ld	s0,16(sp)
    800031d0:	64a2                	ld	s1,8(sp)
    800031d2:	6105                	addi	sp,sp,32
    800031d4:	8082                	ret
    panic("bwrite");
    800031d6:	00005517          	auipc	a0,0x5
    800031da:	48250513          	addi	a0,a0,1154 # 80008658 <syscalls+0x138>
    800031de:	ffffd097          	auipc	ra,0xffffd
    800031e2:	360080e7          	jalr	864(ra) # 8000053e <panic>

00000000800031e6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031e6:	1101                	addi	sp,sp,-32
    800031e8:	ec06                	sd	ra,24(sp)
    800031ea:	e822                	sd	s0,16(sp)
    800031ec:	e426                	sd	s1,8(sp)
    800031ee:	e04a                	sd	s2,0(sp)
    800031f0:	1000                	addi	s0,sp,32
    800031f2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031f4:	01050913          	addi	s2,a0,16
    800031f8:	854a                	mv	a0,s2
    800031fa:	00001097          	auipc	ra,0x1
    800031fe:	422080e7          	jalr	1058(ra) # 8000461c <holdingsleep>
    80003202:	c92d                	beqz	a0,80003274 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003204:	854a                	mv	a0,s2
    80003206:	00001097          	auipc	ra,0x1
    8000320a:	3d2080e7          	jalr	978(ra) # 800045d8 <releasesleep>

  acquire(&bcache.lock);
    8000320e:	00014517          	auipc	a0,0x14
    80003212:	6fa50513          	addi	a0,a0,1786 # 80017908 <bcache>
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	9ce080e7          	jalr	-1586(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000321e:	40bc                	lw	a5,64(s1)
    80003220:	37fd                	addiw	a5,a5,-1
    80003222:	0007871b          	sext.w	a4,a5
    80003226:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003228:	eb05                	bnez	a4,80003258 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000322a:	68bc                	ld	a5,80(s1)
    8000322c:	64b8                	ld	a4,72(s1)
    8000322e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003230:	64bc                	ld	a5,72(s1)
    80003232:	68b8                	ld	a4,80(s1)
    80003234:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003236:	0001c797          	auipc	a5,0x1c
    8000323a:	6d278793          	addi	a5,a5,1746 # 8001f908 <bcache+0x8000>
    8000323e:	2b87b703          	ld	a4,696(a5)
    80003242:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003244:	0001d717          	auipc	a4,0x1d
    80003248:	92c70713          	addi	a4,a4,-1748 # 8001fb70 <bcache+0x8268>
    8000324c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000324e:	2b87b703          	ld	a4,696(a5)
    80003252:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003254:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003258:	00014517          	auipc	a0,0x14
    8000325c:	6b050513          	addi	a0,a0,1712 # 80017908 <bcache>
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	a38080e7          	jalr	-1480(ra) # 80000c98 <release>
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	64a2                	ld	s1,8(sp)
    8000326e:	6902                	ld	s2,0(sp)
    80003270:	6105                	addi	sp,sp,32
    80003272:	8082                	ret
    panic("brelse");
    80003274:	00005517          	auipc	a0,0x5
    80003278:	3ec50513          	addi	a0,a0,1004 # 80008660 <syscalls+0x140>
    8000327c:	ffffd097          	auipc	ra,0xffffd
    80003280:	2c2080e7          	jalr	706(ra) # 8000053e <panic>

0000000080003284 <bpin>:

void
bpin(struct buf *b) {
    80003284:	1101                	addi	sp,sp,-32
    80003286:	ec06                	sd	ra,24(sp)
    80003288:	e822                	sd	s0,16(sp)
    8000328a:	e426                	sd	s1,8(sp)
    8000328c:	1000                	addi	s0,sp,32
    8000328e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003290:	00014517          	auipc	a0,0x14
    80003294:	67850513          	addi	a0,a0,1656 # 80017908 <bcache>
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	94c080e7          	jalr	-1716(ra) # 80000be4 <acquire>
  b->refcnt++;
    800032a0:	40bc                	lw	a5,64(s1)
    800032a2:	2785                	addiw	a5,a5,1
    800032a4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032a6:	00014517          	auipc	a0,0x14
    800032aa:	66250513          	addi	a0,a0,1634 # 80017908 <bcache>
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	9ea080e7          	jalr	-1558(ra) # 80000c98 <release>
}
    800032b6:	60e2                	ld	ra,24(sp)
    800032b8:	6442                	ld	s0,16(sp)
    800032ba:	64a2                	ld	s1,8(sp)
    800032bc:	6105                	addi	sp,sp,32
    800032be:	8082                	ret

00000000800032c0 <bunpin>:

void
bunpin(struct buf *b) {
    800032c0:	1101                	addi	sp,sp,-32
    800032c2:	ec06                	sd	ra,24(sp)
    800032c4:	e822                	sd	s0,16(sp)
    800032c6:	e426                	sd	s1,8(sp)
    800032c8:	1000                	addi	s0,sp,32
    800032ca:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032cc:	00014517          	auipc	a0,0x14
    800032d0:	63c50513          	addi	a0,a0,1596 # 80017908 <bcache>
    800032d4:	ffffe097          	auipc	ra,0xffffe
    800032d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032dc:	40bc                	lw	a5,64(s1)
    800032de:	37fd                	addiw	a5,a5,-1
    800032e0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032e2:	00014517          	auipc	a0,0x14
    800032e6:	62650513          	addi	a0,a0,1574 # 80017908 <bcache>
    800032ea:	ffffe097          	auipc	ra,0xffffe
    800032ee:	9ae080e7          	jalr	-1618(ra) # 80000c98 <release>
}
    800032f2:	60e2                	ld	ra,24(sp)
    800032f4:	6442                	ld	s0,16(sp)
    800032f6:	64a2                	ld	s1,8(sp)
    800032f8:	6105                	addi	sp,sp,32
    800032fa:	8082                	ret

00000000800032fc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032fc:	1101                	addi	sp,sp,-32
    800032fe:	ec06                	sd	ra,24(sp)
    80003300:	e822                	sd	s0,16(sp)
    80003302:	e426                	sd	s1,8(sp)
    80003304:	e04a                	sd	s2,0(sp)
    80003306:	1000                	addi	s0,sp,32
    80003308:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000330a:	00d5d59b          	srliw	a1,a1,0xd
    8000330e:	0001d797          	auipc	a5,0x1d
    80003312:	cd67a783          	lw	a5,-810(a5) # 8001ffe4 <sb+0x1c>
    80003316:	9dbd                	addw	a1,a1,a5
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	d9e080e7          	jalr	-610(ra) # 800030b6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003320:	0074f713          	andi	a4,s1,7
    80003324:	4785                	li	a5,1
    80003326:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000332a:	14ce                	slli	s1,s1,0x33
    8000332c:	90d9                	srli	s1,s1,0x36
    8000332e:	00950733          	add	a4,a0,s1
    80003332:	05874703          	lbu	a4,88(a4)
    80003336:	00e7f6b3          	and	a3,a5,a4
    8000333a:	c69d                	beqz	a3,80003368 <bfree+0x6c>
    8000333c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000333e:	94aa                	add	s1,s1,a0
    80003340:	fff7c793          	not	a5,a5
    80003344:	8ff9                	and	a5,a5,a4
    80003346:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000334a:	00001097          	auipc	ra,0x1
    8000334e:	118080e7          	jalr	280(ra) # 80004462 <log_write>
  brelse(bp);
    80003352:	854a                	mv	a0,s2
    80003354:	00000097          	auipc	ra,0x0
    80003358:	e92080e7          	jalr	-366(ra) # 800031e6 <brelse>
}
    8000335c:	60e2                	ld	ra,24(sp)
    8000335e:	6442                	ld	s0,16(sp)
    80003360:	64a2                	ld	s1,8(sp)
    80003362:	6902                	ld	s2,0(sp)
    80003364:	6105                	addi	sp,sp,32
    80003366:	8082                	ret
    panic("freeing free block");
    80003368:	00005517          	auipc	a0,0x5
    8000336c:	30050513          	addi	a0,a0,768 # 80008668 <syscalls+0x148>
    80003370:	ffffd097          	auipc	ra,0xffffd
    80003374:	1ce080e7          	jalr	462(ra) # 8000053e <panic>

0000000080003378 <balloc>:
{
    80003378:	711d                	addi	sp,sp,-96
    8000337a:	ec86                	sd	ra,88(sp)
    8000337c:	e8a2                	sd	s0,80(sp)
    8000337e:	e4a6                	sd	s1,72(sp)
    80003380:	e0ca                	sd	s2,64(sp)
    80003382:	fc4e                	sd	s3,56(sp)
    80003384:	f852                	sd	s4,48(sp)
    80003386:	f456                	sd	s5,40(sp)
    80003388:	f05a                	sd	s6,32(sp)
    8000338a:	ec5e                	sd	s7,24(sp)
    8000338c:	e862                	sd	s8,16(sp)
    8000338e:	e466                	sd	s9,8(sp)
    80003390:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003392:	0001d797          	auipc	a5,0x1d
    80003396:	c3a7a783          	lw	a5,-966(a5) # 8001ffcc <sb+0x4>
    8000339a:	cbd1                	beqz	a5,8000342e <balloc+0xb6>
    8000339c:	8baa                	mv	s7,a0
    8000339e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033a0:	0001db17          	auipc	s6,0x1d
    800033a4:	c28b0b13          	addi	s6,s6,-984 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033a8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033aa:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ac:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033ae:	6c89                	lui	s9,0x2
    800033b0:	a831                	j	800033cc <balloc+0x54>
    brelse(bp);
    800033b2:	854a                	mv	a0,s2
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	e32080e7          	jalr	-462(ra) # 800031e6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033bc:	015c87bb          	addw	a5,s9,s5
    800033c0:	00078a9b          	sext.w	s5,a5
    800033c4:	004b2703          	lw	a4,4(s6)
    800033c8:	06eaf363          	bgeu	s5,a4,8000342e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033cc:	41fad79b          	sraiw	a5,s5,0x1f
    800033d0:	0137d79b          	srliw	a5,a5,0x13
    800033d4:	015787bb          	addw	a5,a5,s5
    800033d8:	40d7d79b          	sraiw	a5,a5,0xd
    800033dc:	01cb2583          	lw	a1,28(s6)
    800033e0:	9dbd                	addw	a1,a1,a5
    800033e2:	855e                	mv	a0,s7
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	cd2080e7          	jalr	-814(ra) # 800030b6 <bread>
    800033ec:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ee:	004b2503          	lw	a0,4(s6)
    800033f2:	000a849b          	sext.w	s1,s5
    800033f6:	8662                	mv	a2,s8
    800033f8:	faa4fde3          	bgeu	s1,a0,800033b2 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033fc:	41f6579b          	sraiw	a5,a2,0x1f
    80003400:	01d7d69b          	srliw	a3,a5,0x1d
    80003404:	00c6873b          	addw	a4,a3,a2
    80003408:	00777793          	andi	a5,a4,7
    8000340c:	9f95                	subw	a5,a5,a3
    8000340e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003412:	4037571b          	sraiw	a4,a4,0x3
    80003416:	00e906b3          	add	a3,s2,a4
    8000341a:	0586c683          	lbu	a3,88(a3)
    8000341e:	00d7f5b3          	and	a1,a5,a3
    80003422:	cd91                	beqz	a1,8000343e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003424:	2605                	addiw	a2,a2,1
    80003426:	2485                	addiw	s1,s1,1
    80003428:	fd4618e3          	bne	a2,s4,800033f8 <balloc+0x80>
    8000342c:	b759                	j	800033b2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000342e:	00005517          	auipc	a0,0x5
    80003432:	25250513          	addi	a0,a0,594 # 80008680 <syscalls+0x160>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	108080e7          	jalr	264(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000343e:	974a                	add	a4,a4,s2
    80003440:	8fd5                	or	a5,a5,a3
    80003442:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003446:	854a                	mv	a0,s2
    80003448:	00001097          	auipc	ra,0x1
    8000344c:	01a080e7          	jalr	26(ra) # 80004462 <log_write>
        brelse(bp);
    80003450:	854a                	mv	a0,s2
    80003452:	00000097          	auipc	ra,0x0
    80003456:	d94080e7          	jalr	-620(ra) # 800031e6 <brelse>
  bp = bread(dev, bno);
    8000345a:	85a6                	mv	a1,s1
    8000345c:	855e                	mv	a0,s7
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	c58080e7          	jalr	-936(ra) # 800030b6 <bread>
    80003466:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003468:	40000613          	li	a2,1024
    8000346c:	4581                	li	a1,0
    8000346e:	05850513          	addi	a0,a0,88
    80003472:	ffffe097          	auipc	ra,0xffffe
    80003476:	86e080e7          	jalr	-1938(ra) # 80000ce0 <memset>
  log_write(bp);
    8000347a:	854a                	mv	a0,s2
    8000347c:	00001097          	auipc	ra,0x1
    80003480:	fe6080e7          	jalr	-26(ra) # 80004462 <log_write>
  brelse(bp);
    80003484:	854a                	mv	a0,s2
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	d60080e7          	jalr	-672(ra) # 800031e6 <brelse>
}
    8000348e:	8526                	mv	a0,s1
    80003490:	60e6                	ld	ra,88(sp)
    80003492:	6446                	ld	s0,80(sp)
    80003494:	64a6                	ld	s1,72(sp)
    80003496:	6906                	ld	s2,64(sp)
    80003498:	79e2                	ld	s3,56(sp)
    8000349a:	7a42                	ld	s4,48(sp)
    8000349c:	7aa2                	ld	s5,40(sp)
    8000349e:	7b02                	ld	s6,32(sp)
    800034a0:	6be2                	ld	s7,24(sp)
    800034a2:	6c42                	ld	s8,16(sp)
    800034a4:	6ca2                	ld	s9,8(sp)
    800034a6:	6125                	addi	sp,sp,96
    800034a8:	8082                	ret

00000000800034aa <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034aa:	7179                	addi	sp,sp,-48
    800034ac:	f406                	sd	ra,40(sp)
    800034ae:	f022                	sd	s0,32(sp)
    800034b0:	ec26                	sd	s1,24(sp)
    800034b2:	e84a                	sd	s2,16(sp)
    800034b4:	e44e                	sd	s3,8(sp)
    800034b6:	e052                	sd	s4,0(sp)
    800034b8:	1800                	addi	s0,sp,48
    800034ba:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034bc:	47ad                	li	a5,11
    800034be:	04b7fe63          	bgeu	a5,a1,8000351a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034c2:	ff45849b          	addiw	s1,a1,-12
    800034c6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034ca:	0ff00793          	li	a5,255
    800034ce:	0ae7e363          	bltu	a5,a4,80003574 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034d2:	08052583          	lw	a1,128(a0)
    800034d6:	c5ad                	beqz	a1,80003540 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034d8:	00092503          	lw	a0,0(s2)
    800034dc:	00000097          	auipc	ra,0x0
    800034e0:	bda080e7          	jalr	-1062(ra) # 800030b6 <bread>
    800034e4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034e6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034ea:	02049593          	slli	a1,s1,0x20
    800034ee:	9181                	srli	a1,a1,0x20
    800034f0:	058a                	slli	a1,a1,0x2
    800034f2:	00b784b3          	add	s1,a5,a1
    800034f6:	0004a983          	lw	s3,0(s1)
    800034fa:	04098d63          	beqz	s3,80003554 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034fe:	8552                	mv	a0,s4
    80003500:	00000097          	auipc	ra,0x0
    80003504:	ce6080e7          	jalr	-794(ra) # 800031e6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003508:	854e                	mv	a0,s3
    8000350a:	70a2                	ld	ra,40(sp)
    8000350c:	7402                	ld	s0,32(sp)
    8000350e:	64e2                	ld	s1,24(sp)
    80003510:	6942                	ld	s2,16(sp)
    80003512:	69a2                	ld	s3,8(sp)
    80003514:	6a02                	ld	s4,0(sp)
    80003516:	6145                	addi	sp,sp,48
    80003518:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000351a:	02059493          	slli	s1,a1,0x20
    8000351e:	9081                	srli	s1,s1,0x20
    80003520:	048a                	slli	s1,s1,0x2
    80003522:	94aa                	add	s1,s1,a0
    80003524:	0504a983          	lw	s3,80(s1)
    80003528:	fe0990e3          	bnez	s3,80003508 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000352c:	4108                	lw	a0,0(a0)
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	e4a080e7          	jalr	-438(ra) # 80003378 <balloc>
    80003536:	0005099b          	sext.w	s3,a0
    8000353a:	0534a823          	sw	s3,80(s1)
    8000353e:	b7e9                	j	80003508 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003540:	4108                	lw	a0,0(a0)
    80003542:	00000097          	auipc	ra,0x0
    80003546:	e36080e7          	jalr	-458(ra) # 80003378 <balloc>
    8000354a:	0005059b          	sext.w	a1,a0
    8000354e:	08b92023          	sw	a1,128(s2)
    80003552:	b759                	j	800034d8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003554:	00092503          	lw	a0,0(s2)
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	e20080e7          	jalr	-480(ra) # 80003378 <balloc>
    80003560:	0005099b          	sext.w	s3,a0
    80003564:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003568:	8552                	mv	a0,s4
    8000356a:	00001097          	auipc	ra,0x1
    8000356e:	ef8080e7          	jalr	-264(ra) # 80004462 <log_write>
    80003572:	b771                	j	800034fe <bmap+0x54>
  panic("bmap: out of range");
    80003574:	00005517          	auipc	a0,0x5
    80003578:	12450513          	addi	a0,a0,292 # 80008698 <syscalls+0x178>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	fc2080e7          	jalr	-62(ra) # 8000053e <panic>

0000000080003584 <iget>:
{
    80003584:	7179                	addi	sp,sp,-48
    80003586:	f406                	sd	ra,40(sp)
    80003588:	f022                	sd	s0,32(sp)
    8000358a:	ec26                	sd	s1,24(sp)
    8000358c:	e84a                	sd	s2,16(sp)
    8000358e:	e44e                	sd	s3,8(sp)
    80003590:	e052                	sd	s4,0(sp)
    80003592:	1800                	addi	s0,sp,48
    80003594:	89aa                	mv	s3,a0
    80003596:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003598:	0001d517          	auipc	a0,0x1d
    8000359c:	a5050513          	addi	a0,a0,-1456 # 8001ffe8 <itable>
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	644080e7          	jalr	1604(ra) # 80000be4 <acquire>
  empty = 0;
    800035a8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035aa:	0001d497          	auipc	s1,0x1d
    800035ae:	a5648493          	addi	s1,s1,-1450 # 80020000 <itable+0x18>
    800035b2:	0001e697          	auipc	a3,0x1e
    800035b6:	4de68693          	addi	a3,a3,1246 # 80021a90 <log>
    800035ba:	a039                	j	800035c8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035bc:	02090b63          	beqz	s2,800035f2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035c0:	08848493          	addi	s1,s1,136
    800035c4:	02d48a63          	beq	s1,a3,800035f8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035c8:	449c                	lw	a5,8(s1)
    800035ca:	fef059e3          	blez	a5,800035bc <iget+0x38>
    800035ce:	4098                	lw	a4,0(s1)
    800035d0:	ff3716e3          	bne	a4,s3,800035bc <iget+0x38>
    800035d4:	40d8                	lw	a4,4(s1)
    800035d6:	ff4713e3          	bne	a4,s4,800035bc <iget+0x38>
      ip->ref++;
    800035da:	2785                	addiw	a5,a5,1
    800035dc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035de:	0001d517          	auipc	a0,0x1d
    800035e2:	a0a50513          	addi	a0,a0,-1526 # 8001ffe8 <itable>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	6b2080e7          	jalr	1714(ra) # 80000c98 <release>
      return ip;
    800035ee:	8926                	mv	s2,s1
    800035f0:	a03d                	j	8000361e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035f2:	f7f9                	bnez	a5,800035c0 <iget+0x3c>
    800035f4:	8926                	mv	s2,s1
    800035f6:	b7e9                	j	800035c0 <iget+0x3c>
  if(empty == 0)
    800035f8:	02090c63          	beqz	s2,80003630 <iget+0xac>
  ip->dev = dev;
    800035fc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003600:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003604:	4785                	li	a5,1
    80003606:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000360a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000360e:	0001d517          	auipc	a0,0x1d
    80003612:	9da50513          	addi	a0,a0,-1574 # 8001ffe8 <itable>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	682080e7          	jalr	1666(ra) # 80000c98 <release>
}
    8000361e:	854a                	mv	a0,s2
    80003620:	70a2                	ld	ra,40(sp)
    80003622:	7402                	ld	s0,32(sp)
    80003624:	64e2                	ld	s1,24(sp)
    80003626:	6942                	ld	s2,16(sp)
    80003628:	69a2                	ld	s3,8(sp)
    8000362a:	6a02                	ld	s4,0(sp)
    8000362c:	6145                	addi	sp,sp,48
    8000362e:	8082                	ret
    panic("iget: no inodes");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	08050513          	addi	a0,a0,128 # 800086b0 <syscalls+0x190>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f06080e7          	jalr	-250(ra) # 8000053e <panic>

0000000080003640 <fsinit>:
fsinit(int dev) {
    80003640:	7179                	addi	sp,sp,-48
    80003642:	f406                	sd	ra,40(sp)
    80003644:	f022                	sd	s0,32(sp)
    80003646:	ec26                	sd	s1,24(sp)
    80003648:	e84a                	sd	s2,16(sp)
    8000364a:	e44e                	sd	s3,8(sp)
    8000364c:	1800                	addi	s0,sp,48
    8000364e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003650:	4585                	li	a1,1
    80003652:	00000097          	auipc	ra,0x0
    80003656:	a64080e7          	jalr	-1436(ra) # 800030b6 <bread>
    8000365a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000365c:	0001d997          	auipc	s3,0x1d
    80003660:	96c98993          	addi	s3,s3,-1684 # 8001ffc8 <sb>
    80003664:	02000613          	li	a2,32
    80003668:	05850593          	addi	a1,a0,88
    8000366c:	854e                	mv	a0,s3
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	6d2080e7          	jalr	1746(ra) # 80000d40 <memmove>
  brelse(bp);
    80003676:	8526                	mv	a0,s1
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	b6e080e7          	jalr	-1170(ra) # 800031e6 <brelse>
  if(sb.magic != FSMAGIC)
    80003680:	0009a703          	lw	a4,0(s3)
    80003684:	102037b7          	lui	a5,0x10203
    80003688:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000368c:	02f71263          	bne	a4,a5,800036b0 <fsinit+0x70>
  initlog(dev, &sb);
    80003690:	0001d597          	auipc	a1,0x1d
    80003694:	93858593          	addi	a1,a1,-1736 # 8001ffc8 <sb>
    80003698:	854a                	mv	a0,s2
    8000369a:	00001097          	auipc	ra,0x1
    8000369e:	b4c080e7          	jalr	-1204(ra) # 800041e6 <initlog>
}
    800036a2:	70a2                	ld	ra,40(sp)
    800036a4:	7402                	ld	s0,32(sp)
    800036a6:	64e2                	ld	s1,24(sp)
    800036a8:	6942                	ld	s2,16(sp)
    800036aa:	69a2                	ld	s3,8(sp)
    800036ac:	6145                	addi	sp,sp,48
    800036ae:	8082                	ret
    panic("invalid file system");
    800036b0:	00005517          	auipc	a0,0x5
    800036b4:	01050513          	addi	a0,a0,16 # 800086c0 <syscalls+0x1a0>
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	e86080e7          	jalr	-378(ra) # 8000053e <panic>

00000000800036c0 <iinit>:
{
    800036c0:	7179                	addi	sp,sp,-48
    800036c2:	f406                	sd	ra,40(sp)
    800036c4:	f022                	sd	s0,32(sp)
    800036c6:	ec26                	sd	s1,24(sp)
    800036c8:	e84a                	sd	s2,16(sp)
    800036ca:	e44e                	sd	s3,8(sp)
    800036cc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036ce:	00005597          	auipc	a1,0x5
    800036d2:	00a58593          	addi	a1,a1,10 # 800086d8 <syscalls+0x1b8>
    800036d6:	0001d517          	auipc	a0,0x1d
    800036da:	91250513          	addi	a0,a0,-1774 # 8001ffe8 <itable>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	476080e7          	jalr	1142(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036e6:	0001d497          	auipc	s1,0x1d
    800036ea:	92a48493          	addi	s1,s1,-1750 # 80020010 <itable+0x28>
    800036ee:	0001e997          	auipc	s3,0x1e
    800036f2:	3b298993          	addi	s3,s3,946 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036f6:	00005917          	auipc	s2,0x5
    800036fa:	fea90913          	addi	s2,s2,-22 # 800086e0 <syscalls+0x1c0>
    800036fe:	85ca                	mv	a1,s2
    80003700:	8526                	mv	a0,s1
    80003702:	00001097          	auipc	ra,0x1
    80003706:	e46080e7          	jalr	-442(ra) # 80004548 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000370a:	08848493          	addi	s1,s1,136
    8000370e:	ff3498e3          	bne	s1,s3,800036fe <iinit+0x3e>
}
    80003712:	70a2                	ld	ra,40(sp)
    80003714:	7402                	ld	s0,32(sp)
    80003716:	64e2                	ld	s1,24(sp)
    80003718:	6942                	ld	s2,16(sp)
    8000371a:	69a2                	ld	s3,8(sp)
    8000371c:	6145                	addi	sp,sp,48
    8000371e:	8082                	ret

0000000080003720 <ialloc>:
{
    80003720:	715d                	addi	sp,sp,-80
    80003722:	e486                	sd	ra,72(sp)
    80003724:	e0a2                	sd	s0,64(sp)
    80003726:	fc26                	sd	s1,56(sp)
    80003728:	f84a                	sd	s2,48(sp)
    8000372a:	f44e                	sd	s3,40(sp)
    8000372c:	f052                	sd	s4,32(sp)
    8000372e:	ec56                	sd	s5,24(sp)
    80003730:	e85a                	sd	s6,16(sp)
    80003732:	e45e                	sd	s7,8(sp)
    80003734:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003736:	0001d717          	auipc	a4,0x1d
    8000373a:	89e72703          	lw	a4,-1890(a4) # 8001ffd4 <sb+0xc>
    8000373e:	4785                	li	a5,1
    80003740:	04e7fa63          	bgeu	a5,a4,80003794 <ialloc+0x74>
    80003744:	8aaa                	mv	s5,a0
    80003746:	8bae                	mv	s7,a1
    80003748:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000374a:	0001da17          	auipc	s4,0x1d
    8000374e:	87ea0a13          	addi	s4,s4,-1922 # 8001ffc8 <sb>
    80003752:	00048b1b          	sext.w	s6,s1
    80003756:	0044d593          	srli	a1,s1,0x4
    8000375a:	018a2783          	lw	a5,24(s4)
    8000375e:	9dbd                	addw	a1,a1,a5
    80003760:	8556                	mv	a0,s5
    80003762:	00000097          	auipc	ra,0x0
    80003766:	954080e7          	jalr	-1708(ra) # 800030b6 <bread>
    8000376a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000376c:	05850993          	addi	s3,a0,88
    80003770:	00f4f793          	andi	a5,s1,15
    80003774:	079a                	slli	a5,a5,0x6
    80003776:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003778:	00099783          	lh	a5,0(s3)
    8000377c:	c785                	beqz	a5,800037a4 <ialloc+0x84>
    brelse(bp);
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	a68080e7          	jalr	-1432(ra) # 800031e6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003786:	0485                	addi	s1,s1,1
    80003788:	00ca2703          	lw	a4,12(s4)
    8000378c:	0004879b          	sext.w	a5,s1
    80003790:	fce7e1e3          	bltu	a5,a4,80003752 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003794:	00005517          	auipc	a0,0x5
    80003798:	f5450513          	addi	a0,a0,-172 # 800086e8 <syscalls+0x1c8>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	da2080e7          	jalr	-606(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800037a4:	04000613          	li	a2,64
    800037a8:	4581                	li	a1,0
    800037aa:	854e                	mv	a0,s3
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	534080e7          	jalr	1332(ra) # 80000ce0 <memset>
      dip->type = type;
    800037b4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037b8:	854a                	mv	a0,s2
    800037ba:	00001097          	auipc	ra,0x1
    800037be:	ca8080e7          	jalr	-856(ra) # 80004462 <log_write>
      brelse(bp);
    800037c2:	854a                	mv	a0,s2
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	a22080e7          	jalr	-1502(ra) # 800031e6 <brelse>
      return iget(dev, inum);
    800037cc:	85da                	mv	a1,s6
    800037ce:	8556                	mv	a0,s5
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	db4080e7          	jalr	-588(ra) # 80003584 <iget>
}
    800037d8:	60a6                	ld	ra,72(sp)
    800037da:	6406                	ld	s0,64(sp)
    800037dc:	74e2                	ld	s1,56(sp)
    800037de:	7942                	ld	s2,48(sp)
    800037e0:	79a2                	ld	s3,40(sp)
    800037e2:	7a02                	ld	s4,32(sp)
    800037e4:	6ae2                	ld	s5,24(sp)
    800037e6:	6b42                	ld	s6,16(sp)
    800037e8:	6ba2                	ld	s7,8(sp)
    800037ea:	6161                	addi	sp,sp,80
    800037ec:	8082                	ret

00000000800037ee <iupdate>:
{
    800037ee:	1101                	addi	sp,sp,-32
    800037f0:	ec06                	sd	ra,24(sp)
    800037f2:	e822                	sd	s0,16(sp)
    800037f4:	e426                	sd	s1,8(sp)
    800037f6:	e04a                	sd	s2,0(sp)
    800037f8:	1000                	addi	s0,sp,32
    800037fa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037fc:	415c                	lw	a5,4(a0)
    800037fe:	0047d79b          	srliw	a5,a5,0x4
    80003802:	0001c597          	auipc	a1,0x1c
    80003806:	7de5a583          	lw	a1,2014(a1) # 8001ffe0 <sb+0x18>
    8000380a:	9dbd                	addw	a1,a1,a5
    8000380c:	4108                	lw	a0,0(a0)
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	8a8080e7          	jalr	-1880(ra) # 800030b6 <bread>
    80003816:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003818:	05850793          	addi	a5,a0,88
    8000381c:	40c8                	lw	a0,4(s1)
    8000381e:	893d                	andi	a0,a0,15
    80003820:	051a                	slli	a0,a0,0x6
    80003822:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003824:	04449703          	lh	a4,68(s1)
    80003828:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000382c:	04649703          	lh	a4,70(s1)
    80003830:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003834:	04849703          	lh	a4,72(s1)
    80003838:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000383c:	04a49703          	lh	a4,74(s1)
    80003840:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003844:	44f8                	lw	a4,76(s1)
    80003846:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003848:	03400613          	li	a2,52
    8000384c:	05048593          	addi	a1,s1,80
    80003850:	0531                	addi	a0,a0,12
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	4ee080e7          	jalr	1262(ra) # 80000d40 <memmove>
  log_write(bp);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00001097          	auipc	ra,0x1
    80003860:	c06080e7          	jalr	-1018(ra) # 80004462 <log_write>
  brelse(bp);
    80003864:	854a                	mv	a0,s2
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	980080e7          	jalr	-1664(ra) # 800031e6 <brelse>
}
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6902                	ld	s2,0(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret

000000008000387a <idup>:
{
    8000387a:	1101                	addi	sp,sp,-32
    8000387c:	ec06                	sd	ra,24(sp)
    8000387e:	e822                	sd	s0,16(sp)
    80003880:	e426                	sd	s1,8(sp)
    80003882:	1000                	addi	s0,sp,32
    80003884:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003886:	0001c517          	auipc	a0,0x1c
    8000388a:	76250513          	addi	a0,a0,1890 # 8001ffe8 <itable>
    8000388e:	ffffd097          	auipc	ra,0xffffd
    80003892:	356080e7          	jalr	854(ra) # 80000be4 <acquire>
  ip->ref++;
    80003896:	449c                	lw	a5,8(s1)
    80003898:	2785                	addiw	a5,a5,1
    8000389a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000389c:	0001c517          	auipc	a0,0x1c
    800038a0:	74c50513          	addi	a0,a0,1868 # 8001ffe8 <itable>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	3f4080e7          	jalr	1012(ra) # 80000c98 <release>
}
    800038ac:	8526                	mv	a0,s1
    800038ae:	60e2                	ld	ra,24(sp)
    800038b0:	6442                	ld	s0,16(sp)
    800038b2:	64a2                	ld	s1,8(sp)
    800038b4:	6105                	addi	sp,sp,32
    800038b6:	8082                	ret

00000000800038b8 <ilock>:
{
    800038b8:	1101                	addi	sp,sp,-32
    800038ba:	ec06                	sd	ra,24(sp)
    800038bc:	e822                	sd	s0,16(sp)
    800038be:	e426                	sd	s1,8(sp)
    800038c0:	e04a                	sd	s2,0(sp)
    800038c2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038c4:	c115                	beqz	a0,800038e8 <ilock+0x30>
    800038c6:	84aa                	mv	s1,a0
    800038c8:	451c                	lw	a5,8(a0)
    800038ca:	00f05f63          	blez	a5,800038e8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038ce:	0541                	addi	a0,a0,16
    800038d0:	00001097          	auipc	ra,0x1
    800038d4:	cb2080e7          	jalr	-846(ra) # 80004582 <acquiresleep>
  if(ip->valid == 0){
    800038d8:	40bc                	lw	a5,64(s1)
    800038da:	cf99                	beqz	a5,800038f8 <ilock+0x40>
}
    800038dc:	60e2                	ld	ra,24(sp)
    800038de:	6442                	ld	s0,16(sp)
    800038e0:	64a2                	ld	s1,8(sp)
    800038e2:	6902                	ld	s2,0(sp)
    800038e4:	6105                	addi	sp,sp,32
    800038e6:	8082                	ret
    panic("ilock");
    800038e8:	00005517          	auipc	a0,0x5
    800038ec:	e1850513          	addi	a0,a0,-488 # 80008700 <syscalls+0x1e0>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	c4e080e7          	jalr	-946(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038f8:	40dc                	lw	a5,4(s1)
    800038fa:	0047d79b          	srliw	a5,a5,0x4
    800038fe:	0001c597          	auipc	a1,0x1c
    80003902:	6e25a583          	lw	a1,1762(a1) # 8001ffe0 <sb+0x18>
    80003906:	9dbd                	addw	a1,a1,a5
    80003908:	4088                	lw	a0,0(s1)
    8000390a:	fffff097          	auipc	ra,0xfffff
    8000390e:	7ac080e7          	jalr	1964(ra) # 800030b6 <bread>
    80003912:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003914:	05850593          	addi	a1,a0,88
    80003918:	40dc                	lw	a5,4(s1)
    8000391a:	8bbd                	andi	a5,a5,15
    8000391c:	079a                	slli	a5,a5,0x6
    8000391e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003920:	00059783          	lh	a5,0(a1)
    80003924:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003928:	00259783          	lh	a5,2(a1)
    8000392c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003930:	00459783          	lh	a5,4(a1)
    80003934:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003938:	00659783          	lh	a5,6(a1)
    8000393c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003940:	459c                	lw	a5,8(a1)
    80003942:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003944:	03400613          	li	a2,52
    80003948:	05b1                	addi	a1,a1,12
    8000394a:	05048513          	addi	a0,s1,80
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	3f2080e7          	jalr	1010(ra) # 80000d40 <memmove>
    brelse(bp);
    80003956:	854a                	mv	a0,s2
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	88e080e7          	jalr	-1906(ra) # 800031e6 <brelse>
    ip->valid = 1;
    80003960:	4785                	li	a5,1
    80003962:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003964:	04449783          	lh	a5,68(s1)
    80003968:	fbb5                	bnez	a5,800038dc <ilock+0x24>
      panic("ilock: no type");
    8000396a:	00005517          	auipc	a0,0x5
    8000396e:	d9e50513          	addi	a0,a0,-610 # 80008708 <syscalls+0x1e8>
    80003972:	ffffd097          	auipc	ra,0xffffd
    80003976:	bcc080e7          	jalr	-1076(ra) # 8000053e <panic>

000000008000397a <iunlock>:
{
    8000397a:	1101                	addi	sp,sp,-32
    8000397c:	ec06                	sd	ra,24(sp)
    8000397e:	e822                	sd	s0,16(sp)
    80003980:	e426                	sd	s1,8(sp)
    80003982:	e04a                	sd	s2,0(sp)
    80003984:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003986:	c905                	beqz	a0,800039b6 <iunlock+0x3c>
    80003988:	84aa                	mv	s1,a0
    8000398a:	01050913          	addi	s2,a0,16
    8000398e:	854a                	mv	a0,s2
    80003990:	00001097          	auipc	ra,0x1
    80003994:	c8c080e7          	jalr	-884(ra) # 8000461c <holdingsleep>
    80003998:	cd19                	beqz	a0,800039b6 <iunlock+0x3c>
    8000399a:	449c                	lw	a5,8(s1)
    8000399c:	00f05d63          	blez	a5,800039b6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039a0:	854a                	mv	a0,s2
    800039a2:	00001097          	auipc	ra,0x1
    800039a6:	c36080e7          	jalr	-970(ra) # 800045d8 <releasesleep>
}
    800039aa:	60e2                	ld	ra,24(sp)
    800039ac:	6442                	ld	s0,16(sp)
    800039ae:	64a2                	ld	s1,8(sp)
    800039b0:	6902                	ld	s2,0(sp)
    800039b2:	6105                	addi	sp,sp,32
    800039b4:	8082                	ret
    panic("iunlock");
    800039b6:	00005517          	auipc	a0,0x5
    800039ba:	d6250513          	addi	a0,a0,-670 # 80008718 <syscalls+0x1f8>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>

00000000800039c6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039c6:	7179                	addi	sp,sp,-48
    800039c8:	f406                	sd	ra,40(sp)
    800039ca:	f022                	sd	s0,32(sp)
    800039cc:	ec26                	sd	s1,24(sp)
    800039ce:	e84a                	sd	s2,16(sp)
    800039d0:	e44e                	sd	s3,8(sp)
    800039d2:	e052                	sd	s4,0(sp)
    800039d4:	1800                	addi	s0,sp,48
    800039d6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039d8:	05050493          	addi	s1,a0,80
    800039dc:	08050913          	addi	s2,a0,128
    800039e0:	a021                	j	800039e8 <itrunc+0x22>
    800039e2:	0491                	addi	s1,s1,4
    800039e4:	01248d63          	beq	s1,s2,800039fe <itrunc+0x38>
    if(ip->addrs[i]){
    800039e8:	408c                	lw	a1,0(s1)
    800039ea:	dde5                	beqz	a1,800039e2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039ec:	0009a503          	lw	a0,0(s3)
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	90c080e7          	jalr	-1780(ra) # 800032fc <bfree>
      ip->addrs[i] = 0;
    800039f8:	0004a023          	sw	zero,0(s1)
    800039fc:	b7dd                	j	800039e2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039fe:	0809a583          	lw	a1,128(s3)
    80003a02:	e185                	bnez	a1,80003a22 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a04:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a08:	854e                	mv	a0,s3
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	de4080e7          	jalr	-540(ra) # 800037ee <iupdate>
}
    80003a12:	70a2                	ld	ra,40(sp)
    80003a14:	7402                	ld	s0,32(sp)
    80003a16:	64e2                	ld	s1,24(sp)
    80003a18:	6942                	ld	s2,16(sp)
    80003a1a:	69a2                	ld	s3,8(sp)
    80003a1c:	6a02                	ld	s4,0(sp)
    80003a1e:	6145                	addi	sp,sp,48
    80003a20:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a22:	0009a503          	lw	a0,0(s3)
    80003a26:	fffff097          	auipc	ra,0xfffff
    80003a2a:	690080e7          	jalr	1680(ra) # 800030b6 <bread>
    80003a2e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a30:	05850493          	addi	s1,a0,88
    80003a34:	45850913          	addi	s2,a0,1112
    80003a38:	a811                	j	80003a4c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a3a:	0009a503          	lw	a0,0(s3)
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	8be080e7          	jalr	-1858(ra) # 800032fc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a46:	0491                	addi	s1,s1,4
    80003a48:	01248563          	beq	s1,s2,80003a52 <itrunc+0x8c>
      if(a[j])
    80003a4c:	408c                	lw	a1,0(s1)
    80003a4e:	dde5                	beqz	a1,80003a46 <itrunc+0x80>
    80003a50:	b7ed                	j	80003a3a <itrunc+0x74>
    brelse(bp);
    80003a52:	8552                	mv	a0,s4
    80003a54:	fffff097          	auipc	ra,0xfffff
    80003a58:	792080e7          	jalr	1938(ra) # 800031e6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a5c:	0809a583          	lw	a1,128(s3)
    80003a60:	0009a503          	lw	a0,0(s3)
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	898080e7          	jalr	-1896(ra) # 800032fc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a6c:	0809a023          	sw	zero,128(s3)
    80003a70:	bf51                	j	80003a04 <itrunc+0x3e>

0000000080003a72 <iput>:
{
    80003a72:	1101                	addi	sp,sp,-32
    80003a74:	ec06                	sd	ra,24(sp)
    80003a76:	e822                	sd	s0,16(sp)
    80003a78:	e426                	sd	s1,8(sp)
    80003a7a:	e04a                	sd	s2,0(sp)
    80003a7c:	1000                	addi	s0,sp,32
    80003a7e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a80:	0001c517          	auipc	a0,0x1c
    80003a84:	56850513          	addi	a0,a0,1384 # 8001ffe8 <itable>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	15c080e7          	jalr	348(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a90:	4498                	lw	a4,8(s1)
    80003a92:	4785                	li	a5,1
    80003a94:	02f70363          	beq	a4,a5,80003aba <iput+0x48>
  ip->ref--;
    80003a98:	449c                	lw	a5,8(s1)
    80003a9a:	37fd                	addiw	a5,a5,-1
    80003a9c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a9e:	0001c517          	auipc	a0,0x1c
    80003aa2:	54a50513          	addi	a0,a0,1354 # 8001ffe8 <itable>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	1f2080e7          	jalr	498(ra) # 80000c98 <release>
}
    80003aae:	60e2                	ld	ra,24(sp)
    80003ab0:	6442                	ld	s0,16(sp)
    80003ab2:	64a2                	ld	s1,8(sp)
    80003ab4:	6902                	ld	s2,0(sp)
    80003ab6:	6105                	addi	sp,sp,32
    80003ab8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aba:	40bc                	lw	a5,64(s1)
    80003abc:	dff1                	beqz	a5,80003a98 <iput+0x26>
    80003abe:	04a49783          	lh	a5,74(s1)
    80003ac2:	fbf9                	bnez	a5,80003a98 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ac4:	01048913          	addi	s2,s1,16
    80003ac8:	854a                	mv	a0,s2
    80003aca:	00001097          	auipc	ra,0x1
    80003ace:	ab8080e7          	jalr	-1352(ra) # 80004582 <acquiresleep>
    release(&itable.lock);
    80003ad2:	0001c517          	auipc	a0,0x1c
    80003ad6:	51650513          	addi	a0,a0,1302 # 8001ffe8 <itable>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	1be080e7          	jalr	446(ra) # 80000c98 <release>
    itrunc(ip);
    80003ae2:	8526                	mv	a0,s1
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	ee2080e7          	jalr	-286(ra) # 800039c6 <itrunc>
    ip->type = 0;
    80003aec:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003af0:	8526                	mv	a0,s1
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	cfc080e7          	jalr	-772(ra) # 800037ee <iupdate>
    ip->valid = 0;
    80003afa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003afe:	854a                	mv	a0,s2
    80003b00:	00001097          	auipc	ra,0x1
    80003b04:	ad8080e7          	jalr	-1320(ra) # 800045d8 <releasesleep>
    acquire(&itable.lock);
    80003b08:	0001c517          	auipc	a0,0x1c
    80003b0c:	4e050513          	addi	a0,a0,1248 # 8001ffe8 <itable>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	0d4080e7          	jalr	212(ra) # 80000be4 <acquire>
    80003b18:	b741                	j	80003a98 <iput+0x26>

0000000080003b1a <iunlockput>:
{
    80003b1a:	1101                	addi	sp,sp,-32
    80003b1c:	ec06                	sd	ra,24(sp)
    80003b1e:	e822                	sd	s0,16(sp)
    80003b20:	e426                	sd	s1,8(sp)
    80003b22:	1000                	addi	s0,sp,32
    80003b24:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	e54080e7          	jalr	-428(ra) # 8000397a <iunlock>
  iput(ip);
    80003b2e:	8526                	mv	a0,s1
    80003b30:	00000097          	auipc	ra,0x0
    80003b34:	f42080e7          	jalr	-190(ra) # 80003a72 <iput>
}
    80003b38:	60e2                	ld	ra,24(sp)
    80003b3a:	6442                	ld	s0,16(sp)
    80003b3c:	64a2                	ld	s1,8(sp)
    80003b3e:	6105                	addi	sp,sp,32
    80003b40:	8082                	ret

0000000080003b42 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b42:	1141                	addi	sp,sp,-16
    80003b44:	e422                	sd	s0,8(sp)
    80003b46:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b48:	411c                	lw	a5,0(a0)
    80003b4a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b4c:	415c                	lw	a5,4(a0)
    80003b4e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b50:	04451783          	lh	a5,68(a0)
    80003b54:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b58:	04a51783          	lh	a5,74(a0)
    80003b5c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b60:	04c56783          	lwu	a5,76(a0)
    80003b64:	e99c                	sd	a5,16(a1)
}
    80003b66:	6422                	ld	s0,8(sp)
    80003b68:	0141                	addi	sp,sp,16
    80003b6a:	8082                	ret

0000000080003b6c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b6c:	457c                	lw	a5,76(a0)
    80003b6e:	0ed7e963          	bltu	a5,a3,80003c60 <readi+0xf4>
{
    80003b72:	7159                	addi	sp,sp,-112
    80003b74:	f486                	sd	ra,104(sp)
    80003b76:	f0a2                	sd	s0,96(sp)
    80003b78:	eca6                	sd	s1,88(sp)
    80003b7a:	e8ca                	sd	s2,80(sp)
    80003b7c:	e4ce                	sd	s3,72(sp)
    80003b7e:	e0d2                	sd	s4,64(sp)
    80003b80:	fc56                	sd	s5,56(sp)
    80003b82:	f85a                	sd	s6,48(sp)
    80003b84:	f45e                	sd	s7,40(sp)
    80003b86:	f062                	sd	s8,32(sp)
    80003b88:	ec66                	sd	s9,24(sp)
    80003b8a:	e86a                	sd	s10,16(sp)
    80003b8c:	e46e                	sd	s11,8(sp)
    80003b8e:	1880                	addi	s0,sp,112
    80003b90:	8baa                	mv	s7,a0
    80003b92:	8c2e                	mv	s8,a1
    80003b94:	8ab2                	mv	s5,a2
    80003b96:	84b6                	mv	s1,a3
    80003b98:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b9a:	9f35                	addw	a4,a4,a3
    return 0;
    80003b9c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b9e:	0ad76063          	bltu	a4,a3,80003c3e <readi+0xd2>
  if(off + n > ip->size)
    80003ba2:	00e7f463          	bgeu	a5,a4,80003baa <readi+0x3e>
    n = ip->size - off;
    80003ba6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003baa:	0a0b0963          	beqz	s6,80003c5c <readi+0xf0>
    80003bae:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bb4:	5cfd                	li	s9,-1
    80003bb6:	a82d                	j	80003bf0 <readi+0x84>
    80003bb8:	020a1d93          	slli	s11,s4,0x20
    80003bbc:	020ddd93          	srli	s11,s11,0x20
    80003bc0:	05890613          	addi	a2,s2,88
    80003bc4:	86ee                	mv	a3,s11
    80003bc6:	963a                	add	a2,a2,a4
    80003bc8:	85d6                	mv	a1,s5
    80003bca:	8562                	mv	a0,s8
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	a5e080e7          	jalr	-1442(ra) # 8000262a <either_copyout>
    80003bd4:	05950d63          	beq	a0,s9,80003c2e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bd8:	854a                	mv	a0,s2
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	60c080e7          	jalr	1548(ra) # 800031e6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be2:	013a09bb          	addw	s3,s4,s3
    80003be6:	009a04bb          	addw	s1,s4,s1
    80003bea:	9aee                	add	s5,s5,s11
    80003bec:	0569f763          	bgeu	s3,s6,80003c3a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bf0:	000ba903          	lw	s2,0(s7)
    80003bf4:	00a4d59b          	srliw	a1,s1,0xa
    80003bf8:	855e                	mv	a0,s7
    80003bfa:	00000097          	auipc	ra,0x0
    80003bfe:	8b0080e7          	jalr	-1872(ra) # 800034aa <bmap>
    80003c02:	0005059b          	sext.w	a1,a0
    80003c06:	854a                	mv	a0,s2
    80003c08:	fffff097          	auipc	ra,0xfffff
    80003c0c:	4ae080e7          	jalr	1198(ra) # 800030b6 <bread>
    80003c10:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c12:	3ff4f713          	andi	a4,s1,1023
    80003c16:	40ed07bb          	subw	a5,s10,a4
    80003c1a:	413b06bb          	subw	a3,s6,s3
    80003c1e:	8a3e                	mv	s4,a5
    80003c20:	2781                	sext.w	a5,a5
    80003c22:	0006861b          	sext.w	a2,a3
    80003c26:	f8f679e3          	bgeu	a2,a5,80003bb8 <readi+0x4c>
    80003c2a:	8a36                	mv	s4,a3
    80003c2c:	b771                	j	80003bb8 <readi+0x4c>
      brelse(bp);
    80003c2e:	854a                	mv	a0,s2
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	5b6080e7          	jalr	1462(ra) # 800031e6 <brelse>
      tot = -1;
    80003c38:	59fd                	li	s3,-1
  }
  return tot;
    80003c3a:	0009851b          	sext.w	a0,s3
}
    80003c3e:	70a6                	ld	ra,104(sp)
    80003c40:	7406                	ld	s0,96(sp)
    80003c42:	64e6                	ld	s1,88(sp)
    80003c44:	6946                	ld	s2,80(sp)
    80003c46:	69a6                	ld	s3,72(sp)
    80003c48:	6a06                	ld	s4,64(sp)
    80003c4a:	7ae2                	ld	s5,56(sp)
    80003c4c:	7b42                	ld	s6,48(sp)
    80003c4e:	7ba2                	ld	s7,40(sp)
    80003c50:	7c02                	ld	s8,32(sp)
    80003c52:	6ce2                	ld	s9,24(sp)
    80003c54:	6d42                	ld	s10,16(sp)
    80003c56:	6da2                	ld	s11,8(sp)
    80003c58:	6165                	addi	sp,sp,112
    80003c5a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c5c:	89da                	mv	s3,s6
    80003c5e:	bff1                	j	80003c3a <readi+0xce>
    return 0;
    80003c60:	4501                	li	a0,0
}
    80003c62:	8082                	ret

0000000080003c64 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c64:	457c                	lw	a5,76(a0)
    80003c66:	10d7e863          	bltu	a5,a3,80003d76 <writei+0x112>
{
    80003c6a:	7159                	addi	sp,sp,-112
    80003c6c:	f486                	sd	ra,104(sp)
    80003c6e:	f0a2                	sd	s0,96(sp)
    80003c70:	eca6                	sd	s1,88(sp)
    80003c72:	e8ca                	sd	s2,80(sp)
    80003c74:	e4ce                	sd	s3,72(sp)
    80003c76:	e0d2                	sd	s4,64(sp)
    80003c78:	fc56                	sd	s5,56(sp)
    80003c7a:	f85a                	sd	s6,48(sp)
    80003c7c:	f45e                	sd	s7,40(sp)
    80003c7e:	f062                	sd	s8,32(sp)
    80003c80:	ec66                	sd	s9,24(sp)
    80003c82:	e86a                	sd	s10,16(sp)
    80003c84:	e46e                	sd	s11,8(sp)
    80003c86:	1880                	addi	s0,sp,112
    80003c88:	8b2a                	mv	s6,a0
    80003c8a:	8c2e                	mv	s8,a1
    80003c8c:	8ab2                	mv	s5,a2
    80003c8e:	8936                	mv	s2,a3
    80003c90:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c92:	00e687bb          	addw	a5,a3,a4
    80003c96:	0ed7e263          	bltu	a5,a3,80003d7a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c9a:	00043737          	lui	a4,0x43
    80003c9e:	0ef76063          	bltu	a4,a5,80003d7e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ca2:	0c0b8863          	beqz	s7,80003d72 <writei+0x10e>
    80003ca6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cac:	5cfd                	li	s9,-1
    80003cae:	a091                	j	80003cf2 <writei+0x8e>
    80003cb0:	02099d93          	slli	s11,s3,0x20
    80003cb4:	020ddd93          	srli	s11,s11,0x20
    80003cb8:	05848513          	addi	a0,s1,88
    80003cbc:	86ee                	mv	a3,s11
    80003cbe:	8656                	mv	a2,s5
    80003cc0:	85e2                	mv	a1,s8
    80003cc2:	953a                	add	a0,a0,a4
    80003cc4:	fffff097          	auipc	ra,0xfffff
    80003cc8:	9bc080e7          	jalr	-1604(ra) # 80002680 <either_copyin>
    80003ccc:	07950263          	beq	a0,s9,80003d30 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cd0:	8526                	mv	a0,s1
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	790080e7          	jalr	1936(ra) # 80004462 <log_write>
    brelse(bp);
    80003cda:	8526                	mv	a0,s1
    80003cdc:	fffff097          	auipc	ra,0xfffff
    80003ce0:	50a080e7          	jalr	1290(ra) # 800031e6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ce4:	01498a3b          	addw	s4,s3,s4
    80003ce8:	0129893b          	addw	s2,s3,s2
    80003cec:	9aee                	add	s5,s5,s11
    80003cee:	057a7663          	bgeu	s4,s7,80003d3a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cf2:	000b2483          	lw	s1,0(s6)
    80003cf6:	00a9559b          	srliw	a1,s2,0xa
    80003cfa:	855a                	mv	a0,s6
    80003cfc:	fffff097          	auipc	ra,0xfffff
    80003d00:	7ae080e7          	jalr	1966(ra) # 800034aa <bmap>
    80003d04:	0005059b          	sext.w	a1,a0
    80003d08:	8526                	mv	a0,s1
    80003d0a:	fffff097          	auipc	ra,0xfffff
    80003d0e:	3ac080e7          	jalr	940(ra) # 800030b6 <bread>
    80003d12:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d14:	3ff97713          	andi	a4,s2,1023
    80003d18:	40ed07bb          	subw	a5,s10,a4
    80003d1c:	414b86bb          	subw	a3,s7,s4
    80003d20:	89be                	mv	s3,a5
    80003d22:	2781                	sext.w	a5,a5
    80003d24:	0006861b          	sext.w	a2,a3
    80003d28:	f8f674e3          	bgeu	a2,a5,80003cb0 <writei+0x4c>
    80003d2c:	89b6                	mv	s3,a3
    80003d2e:	b749                	j	80003cb0 <writei+0x4c>
      brelse(bp);
    80003d30:	8526                	mv	a0,s1
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	4b4080e7          	jalr	1204(ra) # 800031e6 <brelse>
  }

  if(off > ip->size)
    80003d3a:	04cb2783          	lw	a5,76(s6)
    80003d3e:	0127f463          	bgeu	a5,s2,80003d46 <writei+0xe2>
    ip->size = off;
    80003d42:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d46:	855a                	mv	a0,s6
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	aa6080e7          	jalr	-1370(ra) # 800037ee <iupdate>

  return tot;
    80003d50:	000a051b          	sext.w	a0,s4
}
    80003d54:	70a6                	ld	ra,104(sp)
    80003d56:	7406                	ld	s0,96(sp)
    80003d58:	64e6                	ld	s1,88(sp)
    80003d5a:	6946                	ld	s2,80(sp)
    80003d5c:	69a6                	ld	s3,72(sp)
    80003d5e:	6a06                	ld	s4,64(sp)
    80003d60:	7ae2                	ld	s5,56(sp)
    80003d62:	7b42                	ld	s6,48(sp)
    80003d64:	7ba2                	ld	s7,40(sp)
    80003d66:	7c02                	ld	s8,32(sp)
    80003d68:	6ce2                	ld	s9,24(sp)
    80003d6a:	6d42                	ld	s10,16(sp)
    80003d6c:	6da2                	ld	s11,8(sp)
    80003d6e:	6165                	addi	sp,sp,112
    80003d70:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d72:	8a5e                	mv	s4,s7
    80003d74:	bfc9                	j	80003d46 <writei+0xe2>
    return -1;
    80003d76:	557d                	li	a0,-1
}
    80003d78:	8082                	ret
    return -1;
    80003d7a:	557d                	li	a0,-1
    80003d7c:	bfe1                	j	80003d54 <writei+0xf0>
    return -1;
    80003d7e:	557d                	li	a0,-1
    80003d80:	bfd1                	j	80003d54 <writei+0xf0>

0000000080003d82 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d82:	1141                	addi	sp,sp,-16
    80003d84:	e406                	sd	ra,8(sp)
    80003d86:	e022                	sd	s0,0(sp)
    80003d88:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d8a:	4639                	li	a2,14
    80003d8c:	ffffd097          	auipc	ra,0xffffd
    80003d90:	02c080e7          	jalr	44(ra) # 80000db8 <strncmp>
}
    80003d94:	60a2                	ld	ra,8(sp)
    80003d96:	6402                	ld	s0,0(sp)
    80003d98:	0141                	addi	sp,sp,16
    80003d9a:	8082                	ret

0000000080003d9c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d9c:	7139                	addi	sp,sp,-64
    80003d9e:	fc06                	sd	ra,56(sp)
    80003da0:	f822                	sd	s0,48(sp)
    80003da2:	f426                	sd	s1,40(sp)
    80003da4:	f04a                	sd	s2,32(sp)
    80003da6:	ec4e                	sd	s3,24(sp)
    80003da8:	e852                	sd	s4,16(sp)
    80003daa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dac:	04451703          	lh	a4,68(a0)
    80003db0:	4785                	li	a5,1
    80003db2:	00f71a63          	bne	a4,a5,80003dc6 <dirlookup+0x2a>
    80003db6:	892a                	mv	s2,a0
    80003db8:	89ae                	mv	s3,a1
    80003dba:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dbc:	457c                	lw	a5,76(a0)
    80003dbe:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dc0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc2:	e79d                	bnez	a5,80003df0 <dirlookup+0x54>
    80003dc4:	a8a5                	j	80003e3c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dc6:	00005517          	auipc	a0,0x5
    80003dca:	95a50513          	addi	a0,a0,-1702 # 80008720 <syscalls+0x200>
    80003dce:	ffffc097          	auipc	ra,0xffffc
    80003dd2:	770080e7          	jalr	1904(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dd6:	00005517          	auipc	a0,0x5
    80003dda:	96250513          	addi	a0,a0,-1694 # 80008738 <syscalls+0x218>
    80003dde:	ffffc097          	auipc	ra,0xffffc
    80003de2:	760080e7          	jalr	1888(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de6:	24c1                	addiw	s1,s1,16
    80003de8:	04c92783          	lw	a5,76(s2)
    80003dec:	04f4f763          	bgeu	s1,a5,80003e3a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003df0:	4741                	li	a4,16
    80003df2:	86a6                	mv	a3,s1
    80003df4:	fc040613          	addi	a2,s0,-64
    80003df8:	4581                	li	a1,0
    80003dfa:	854a                	mv	a0,s2
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	d70080e7          	jalr	-656(ra) # 80003b6c <readi>
    80003e04:	47c1                	li	a5,16
    80003e06:	fcf518e3          	bne	a0,a5,80003dd6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e0a:	fc045783          	lhu	a5,-64(s0)
    80003e0e:	dfe1                	beqz	a5,80003de6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e10:	fc240593          	addi	a1,s0,-62
    80003e14:	854e                	mv	a0,s3
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	f6c080e7          	jalr	-148(ra) # 80003d82 <namecmp>
    80003e1e:	f561                	bnez	a0,80003de6 <dirlookup+0x4a>
      if(poff)
    80003e20:	000a0463          	beqz	s4,80003e28 <dirlookup+0x8c>
        *poff = off;
    80003e24:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e28:	fc045583          	lhu	a1,-64(s0)
    80003e2c:	00092503          	lw	a0,0(s2)
    80003e30:	fffff097          	auipc	ra,0xfffff
    80003e34:	754080e7          	jalr	1876(ra) # 80003584 <iget>
    80003e38:	a011                	j	80003e3c <dirlookup+0xa0>
  return 0;
    80003e3a:	4501                	li	a0,0
}
    80003e3c:	70e2                	ld	ra,56(sp)
    80003e3e:	7442                	ld	s0,48(sp)
    80003e40:	74a2                	ld	s1,40(sp)
    80003e42:	7902                	ld	s2,32(sp)
    80003e44:	69e2                	ld	s3,24(sp)
    80003e46:	6a42                	ld	s4,16(sp)
    80003e48:	6121                	addi	sp,sp,64
    80003e4a:	8082                	ret

0000000080003e4c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e4c:	711d                	addi	sp,sp,-96
    80003e4e:	ec86                	sd	ra,88(sp)
    80003e50:	e8a2                	sd	s0,80(sp)
    80003e52:	e4a6                	sd	s1,72(sp)
    80003e54:	e0ca                	sd	s2,64(sp)
    80003e56:	fc4e                	sd	s3,56(sp)
    80003e58:	f852                	sd	s4,48(sp)
    80003e5a:	f456                	sd	s5,40(sp)
    80003e5c:	f05a                	sd	s6,32(sp)
    80003e5e:	ec5e                	sd	s7,24(sp)
    80003e60:	e862                	sd	s8,16(sp)
    80003e62:	e466                	sd	s9,8(sp)
    80003e64:	1080                	addi	s0,sp,96
    80003e66:	84aa                	mv	s1,a0
    80003e68:	8b2e                	mv	s6,a1
    80003e6a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e6c:	00054703          	lbu	a4,0(a0)
    80003e70:	02f00793          	li	a5,47
    80003e74:	02f70363          	beq	a4,a5,80003e9a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e78:	ffffe097          	auipc	ra,0xffffe
    80003e7c:	bfc080e7          	jalr	-1028(ra) # 80001a74 <myproc>
    80003e80:	15053503          	ld	a0,336(a0)
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	9f6080e7          	jalr	-1546(ra) # 8000387a <idup>
    80003e8c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e8e:	02f00913          	li	s2,47
  len = path - s;
    80003e92:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e94:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e96:	4c05                	li	s8,1
    80003e98:	a865                	j	80003f50 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e9a:	4585                	li	a1,1
    80003e9c:	4505                	li	a0,1
    80003e9e:	fffff097          	auipc	ra,0xfffff
    80003ea2:	6e6080e7          	jalr	1766(ra) # 80003584 <iget>
    80003ea6:	89aa                	mv	s3,a0
    80003ea8:	b7dd                	j	80003e8e <namex+0x42>
      iunlockput(ip);
    80003eaa:	854e                	mv	a0,s3
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	c6e080e7          	jalr	-914(ra) # 80003b1a <iunlockput>
      return 0;
    80003eb4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eb6:	854e                	mv	a0,s3
    80003eb8:	60e6                	ld	ra,88(sp)
    80003eba:	6446                	ld	s0,80(sp)
    80003ebc:	64a6                	ld	s1,72(sp)
    80003ebe:	6906                	ld	s2,64(sp)
    80003ec0:	79e2                	ld	s3,56(sp)
    80003ec2:	7a42                	ld	s4,48(sp)
    80003ec4:	7aa2                	ld	s5,40(sp)
    80003ec6:	7b02                	ld	s6,32(sp)
    80003ec8:	6be2                	ld	s7,24(sp)
    80003eca:	6c42                	ld	s8,16(sp)
    80003ecc:	6ca2                	ld	s9,8(sp)
    80003ece:	6125                	addi	sp,sp,96
    80003ed0:	8082                	ret
      iunlock(ip);
    80003ed2:	854e                	mv	a0,s3
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	aa6080e7          	jalr	-1370(ra) # 8000397a <iunlock>
      return ip;
    80003edc:	bfe9                	j	80003eb6 <namex+0x6a>
      iunlockput(ip);
    80003ede:	854e                	mv	a0,s3
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	c3a080e7          	jalr	-966(ra) # 80003b1a <iunlockput>
      return 0;
    80003ee8:	89d2                	mv	s3,s4
    80003eea:	b7f1                	j	80003eb6 <namex+0x6a>
  len = path - s;
    80003eec:	40b48633          	sub	a2,s1,a1
    80003ef0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ef4:	094cd463          	bge	s9,s4,80003f7c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ef8:	4639                	li	a2,14
    80003efa:	8556                	mv	a0,s5
    80003efc:	ffffd097          	auipc	ra,0xffffd
    80003f00:	e44080e7          	jalr	-444(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f04:	0004c783          	lbu	a5,0(s1)
    80003f08:	01279763          	bne	a5,s2,80003f16 <namex+0xca>
    path++;
    80003f0c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f0e:	0004c783          	lbu	a5,0(s1)
    80003f12:	ff278de3          	beq	a5,s2,80003f0c <namex+0xc0>
    ilock(ip);
    80003f16:	854e                	mv	a0,s3
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	9a0080e7          	jalr	-1632(ra) # 800038b8 <ilock>
    if(ip->type != T_DIR){
    80003f20:	04499783          	lh	a5,68(s3)
    80003f24:	f98793e3          	bne	a5,s8,80003eaa <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f28:	000b0563          	beqz	s6,80003f32 <namex+0xe6>
    80003f2c:	0004c783          	lbu	a5,0(s1)
    80003f30:	d3cd                	beqz	a5,80003ed2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f32:	865e                	mv	a2,s7
    80003f34:	85d6                	mv	a1,s5
    80003f36:	854e                	mv	a0,s3
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	e64080e7          	jalr	-412(ra) # 80003d9c <dirlookup>
    80003f40:	8a2a                	mv	s4,a0
    80003f42:	dd51                	beqz	a0,80003ede <namex+0x92>
    iunlockput(ip);
    80003f44:	854e                	mv	a0,s3
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	bd4080e7          	jalr	-1068(ra) # 80003b1a <iunlockput>
    ip = next;
    80003f4e:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f50:	0004c783          	lbu	a5,0(s1)
    80003f54:	05279763          	bne	a5,s2,80003fa2 <namex+0x156>
    path++;
    80003f58:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f5a:	0004c783          	lbu	a5,0(s1)
    80003f5e:	ff278de3          	beq	a5,s2,80003f58 <namex+0x10c>
  if(*path == 0)
    80003f62:	c79d                	beqz	a5,80003f90 <namex+0x144>
    path++;
    80003f64:	85a6                	mv	a1,s1
  len = path - s;
    80003f66:	8a5e                	mv	s4,s7
    80003f68:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f6a:	01278963          	beq	a5,s2,80003f7c <namex+0x130>
    80003f6e:	dfbd                	beqz	a5,80003eec <namex+0xa0>
    path++;
    80003f70:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f72:	0004c783          	lbu	a5,0(s1)
    80003f76:	ff279ce3          	bne	a5,s2,80003f6e <namex+0x122>
    80003f7a:	bf8d                	j	80003eec <namex+0xa0>
    memmove(name, s, len);
    80003f7c:	2601                	sext.w	a2,a2
    80003f7e:	8556                	mv	a0,s5
    80003f80:	ffffd097          	auipc	ra,0xffffd
    80003f84:	dc0080e7          	jalr	-576(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f88:	9a56                	add	s4,s4,s5
    80003f8a:	000a0023          	sb	zero,0(s4)
    80003f8e:	bf9d                	j	80003f04 <namex+0xb8>
  if(nameiparent){
    80003f90:	f20b03e3          	beqz	s6,80003eb6 <namex+0x6a>
    iput(ip);
    80003f94:	854e                	mv	a0,s3
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	adc080e7          	jalr	-1316(ra) # 80003a72 <iput>
    return 0;
    80003f9e:	4981                	li	s3,0
    80003fa0:	bf19                	j	80003eb6 <namex+0x6a>
  if(*path == 0)
    80003fa2:	d7fd                	beqz	a5,80003f90 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fa4:	0004c783          	lbu	a5,0(s1)
    80003fa8:	85a6                	mv	a1,s1
    80003faa:	b7d1                	j	80003f6e <namex+0x122>

0000000080003fac <dirlink>:
{
    80003fac:	7139                	addi	sp,sp,-64
    80003fae:	fc06                	sd	ra,56(sp)
    80003fb0:	f822                	sd	s0,48(sp)
    80003fb2:	f426                	sd	s1,40(sp)
    80003fb4:	f04a                	sd	s2,32(sp)
    80003fb6:	ec4e                	sd	s3,24(sp)
    80003fb8:	e852                	sd	s4,16(sp)
    80003fba:	0080                	addi	s0,sp,64
    80003fbc:	892a                	mv	s2,a0
    80003fbe:	8a2e                	mv	s4,a1
    80003fc0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fc2:	4601                	li	a2,0
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	dd8080e7          	jalr	-552(ra) # 80003d9c <dirlookup>
    80003fcc:	e93d                	bnez	a0,80004042 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fce:	04c92483          	lw	s1,76(s2)
    80003fd2:	c49d                	beqz	s1,80004000 <dirlink+0x54>
    80003fd4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fd6:	4741                	li	a4,16
    80003fd8:	86a6                	mv	a3,s1
    80003fda:	fc040613          	addi	a2,s0,-64
    80003fde:	4581                	li	a1,0
    80003fe0:	854a                	mv	a0,s2
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	b8a080e7          	jalr	-1142(ra) # 80003b6c <readi>
    80003fea:	47c1                	li	a5,16
    80003fec:	06f51163          	bne	a0,a5,8000404e <dirlink+0xa2>
    if(de.inum == 0)
    80003ff0:	fc045783          	lhu	a5,-64(s0)
    80003ff4:	c791                	beqz	a5,80004000 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff6:	24c1                	addiw	s1,s1,16
    80003ff8:	04c92783          	lw	a5,76(s2)
    80003ffc:	fcf4ede3          	bltu	s1,a5,80003fd6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004000:	4639                	li	a2,14
    80004002:	85d2                	mv	a1,s4
    80004004:	fc240513          	addi	a0,s0,-62
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	dec080e7          	jalr	-532(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004010:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004014:	4741                	li	a4,16
    80004016:	86a6                	mv	a3,s1
    80004018:	fc040613          	addi	a2,s0,-64
    8000401c:	4581                	li	a1,0
    8000401e:	854a                	mv	a0,s2
    80004020:	00000097          	auipc	ra,0x0
    80004024:	c44080e7          	jalr	-956(ra) # 80003c64 <writei>
    80004028:	872a                	mv	a4,a0
    8000402a:	47c1                	li	a5,16
  return 0;
    8000402c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402e:	02f71863          	bne	a4,a5,8000405e <dirlink+0xb2>
}
    80004032:	70e2                	ld	ra,56(sp)
    80004034:	7442                	ld	s0,48(sp)
    80004036:	74a2                	ld	s1,40(sp)
    80004038:	7902                	ld	s2,32(sp)
    8000403a:	69e2                	ld	s3,24(sp)
    8000403c:	6a42                	ld	s4,16(sp)
    8000403e:	6121                	addi	sp,sp,64
    80004040:	8082                	ret
    iput(ip);
    80004042:	00000097          	auipc	ra,0x0
    80004046:	a30080e7          	jalr	-1488(ra) # 80003a72 <iput>
    return -1;
    8000404a:	557d                	li	a0,-1
    8000404c:	b7dd                	j	80004032 <dirlink+0x86>
      panic("dirlink read");
    8000404e:	00004517          	auipc	a0,0x4
    80004052:	6fa50513          	addi	a0,a0,1786 # 80008748 <syscalls+0x228>
    80004056:	ffffc097          	auipc	ra,0xffffc
    8000405a:	4e8080e7          	jalr	1256(ra) # 8000053e <panic>
    panic("dirlink");
    8000405e:	00004517          	auipc	a0,0x4
    80004062:	7fa50513          	addi	a0,a0,2042 # 80008858 <syscalls+0x338>
    80004066:	ffffc097          	auipc	ra,0xffffc
    8000406a:	4d8080e7          	jalr	1240(ra) # 8000053e <panic>

000000008000406e <namei>:

struct inode*
namei(char *path)
{
    8000406e:	1101                	addi	sp,sp,-32
    80004070:	ec06                	sd	ra,24(sp)
    80004072:	e822                	sd	s0,16(sp)
    80004074:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004076:	fe040613          	addi	a2,s0,-32
    8000407a:	4581                	li	a1,0
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	dd0080e7          	jalr	-560(ra) # 80003e4c <namex>
}
    80004084:	60e2                	ld	ra,24(sp)
    80004086:	6442                	ld	s0,16(sp)
    80004088:	6105                	addi	sp,sp,32
    8000408a:	8082                	ret

000000008000408c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000408c:	1141                	addi	sp,sp,-16
    8000408e:	e406                	sd	ra,8(sp)
    80004090:	e022                	sd	s0,0(sp)
    80004092:	0800                	addi	s0,sp,16
    80004094:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004096:	4585                	li	a1,1
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	db4080e7          	jalr	-588(ra) # 80003e4c <namex>
}
    800040a0:	60a2                	ld	ra,8(sp)
    800040a2:	6402                	ld	s0,0(sp)
    800040a4:	0141                	addi	sp,sp,16
    800040a6:	8082                	ret

00000000800040a8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040a8:	1101                	addi	sp,sp,-32
    800040aa:	ec06                	sd	ra,24(sp)
    800040ac:	e822                	sd	s0,16(sp)
    800040ae:	e426                	sd	s1,8(sp)
    800040b0:	e04a                	sd	s2,0(sp)
    800040b2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040b4:	0001e917          	auipc	s2,0x1e
    800040b8:	9dc90913          	addi	s2,s2,-1572 # 80021a90 <log>
    800040bc:	01892583          	lw	a1,24(s2)
    800040c0:	02892503          	lw	a0,40(s2)
    800040c4:	fffff097          	auipc	ra,0xfffff
    800040c8:	ff2080e7          	jalr	-14(ra) # 800030b6 <bread>
    800040cc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040ce:	02c92683          	lw	a3,44(s2)
    800040d2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040d4:	02d05763          	blez	a3,80004102 <write_head+0x5a>
    800040d8:	0001e797          	auipc	a5,0x1e
    800040dc:	9e878793          	addi	a5,a5,-1560 # 80021ac0 <log+0x30>
    800040e0:	05c50713          	addi	a4,a0,92
    800040e4:	36fd                	addiw	a3,a3,-1
    800040e6:	1682                	slli	a3,a3,0x20
    800040e8:	9281                	srli	a3,a3,0x20
    800040ea:	068a                	slli	a3,a3,0x2
    800040ec:	0001e617          	auipc	a2,0x1e
    800040f0:	9d860613          	addi	a2,a2,-1576 # 80021ac4 <log+0x34>
    800040f4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040f6:	4390                	lw	a2,0(a5)
    800040f8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040fa:	0791                	addi	a5,a5,4
    800040fc:	0711                	addi	a4,a4,4
    800040fe:	fed79ce3          	bne	a5,a3,800040f6 <write_head+0x4e>
  }
  bwrite(buf);
    80004102:	8526                	mv	a0,s1
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	0a4080e7          	jalr	164(ra) # 800031a8 <bwrite>
  brelse(buf);
    8000410c:	8526                	mv	a0,s1
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	0d8080e7          	jalr	216(ra) # 800031e6 <brelse>
}
    80004116:	60e2                	ld	ra,24(sp)
    80004118:	6442                	ld	s0,16(sp)
    8000411a:	64a2                	ld	s1,8(sp)
    8000411c:	6902                	ld	s2,0(sp)
    8000411e:	6105                	addi	sp,sp,32
    80004120:	8082                	ret

0000000080004122 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004122:	0001e797          	auipc	a5,0x1e
    80004126:	99a7a783          	lw	a5,-1638(a5) # 80021abc <log+0x2c>
    8000412a:	0af05d63          	blez	a5,800041e4 <install_trans+0xc2>
{
    8000412e:	7139                	addi	sp,sp,-64
    80004130:	fc06                	sd	ra,56(sp)
    80004132:	f822                	sd	s0,48(sp)
    80004134:	f426                	sd	s1,40(sp)
    80004136:	f04a                	sd	s2,32(sp)
    80004138:	ec4e                	sd	s3,24(sp)
    8000413a:	e852                	sd	s4,16(sp)
    8000413c:	e456                	sd	s5,8(sp)
    8000413e:	e05a                	sd	s6,0(sp)
    80004140:	0080                	addi	s0,sp,64
    80004142:	8b2a                	mv	s6,a0
    80004144:	0001ea97          	auipc	s5,0x1e
    80004148:	97ca8a93          	addi	s5,s5,-1668 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000414c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000414e:	0001e997          	auipc	s3,0x1e
    80004152:	94298993          	addi	s3,s3,-1726 # 80021a90 <log>
    80004156:	a035                	j	80004182 <install_trans+0x60>
      bunpin(dbuf);
    80004158:	8526                	mv	a0,s1
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	166080e7          	jalr	358(ra) # 800032c0 <bunpin>
    brelse(lbuf);
    80004162:	854a                	mv	a0,s2
    80004164:	fffff097          	auipc	ra,0xfffff
    80004168:	082080e7          	jalr	130(ra) # 800031e6 <brelse>
    brelse(dbuf);
    8000416c:	8526                	mv	a0,s1
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	078080e7          	jalr	120(ra) # 800031e6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004176:	2a05                	addiw	s4,s4,1
    80004178:	0a91                	addi	s5,s5,4
    8000417a:	02c9a783          	lw	a5,44(s3)
    8000417e:	04fa5963          	bge	s4,a5,800041d0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004182:	0189a583          	lw	a1,24(s3)
    80004186:	014585bb          	addw	a1,a1,s4
    8000418a:	2585                	addiw	a1,a1,1
    8000418c:	0289a503          	lw	a0,40(s3)
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	f26080e7          	jalr	-218(ra) # 800030b6 <bread>
    80004198:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000419a:	000aa583          	lw	a1,0(s5)
    8000419e:	0289a503          	lw	a0,40(s3)
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	f14080e7          	jalr	-236(ra) # 800030b6 <bread>
    800041aa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041ac:	40000613          	li	a2,1024
    800041b0:	05890593          	addi	a1,s2,88
    800041b4:	05850513          	addi	a0,a0,88
    800041b8:	ffffd097          	auipc	ra,0xffffd
    800041bc:	b88080e7          	jalr	-1144(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041c0:	8526                	mv	a0,s1
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	fe6080e7          	jalr	-26(ra) # 800031a8 <bwrite>
    if(recovering == 0)
    800041ca:	f80b1ce3          	bnez	s6,80004162 <install_trans+0x40>
    800041ce:	b769                	j	80004158 <install_trans+0x36>
}
    800041d0:	70e2                	ld	ra,56(sp)
    800041d2:	7442                	ld	s0,48(sp)
    800041d4:	74a2                	ld	s1,40(sp)
    800041d6:	7902                	ld	s2,32(sp)
    800041d8:	69e2                	ld	s3,24(sp)
    800041da:	6a42                	ld	s4,16(sp)
    800041dc:	6aa2                	ld	s5,8(sp)
    800041de:	6b02                	ld	s6,0(sp)
    800041e0:	6121                	addi	sp,sp,64
    800041e2:	8082                	ret
    800041e4:	8082                	ret

00000000800041e6 <initlog>:
{
    800041e6:	7179                	addi	sp,sp,-48
    800041e8:	f406                	sd	ra,40(sp)
    800041ea:	f022                	sd	s0,32(sp)
    800041ec:	ec26                	sd	s1,24(sp)
    800041ee:	e84a                	sd	s2,16(sp)
    800041f0:	e44e                	sd	s3,8(sp)
    800041f2:	1800                	addi	s0,sp,48
    800041f4:	892a                	mv	s2,a0
    800041f6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041f8:	0001e497          	auipc	s1,0x1e
    800041fc:	89848493          	addi	s1,s1,-1896 # 80021a90 <log>
    80004200:	00004597          	auipc	a1,0x4
    80004204:	55858593          	addi	a1,a1,1368 # 80008758 <syscalls+0x238>
    80004208:	8526                	mv	a0,s1
    8000420a:	ffffd097          	auipc	ra,0xffffd
    8000420e:	94a080e7          	jalr	-1718(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004212:	0149a583          	lw	a1,20(s3)
    80004216:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004218:	0109a783          	lw	a5,16(s3)
    8000421c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000421e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004222:	854a                	mv	a0,s2
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	e92080e7          	jalr	-366(ra) # 800030b6 <bread>
  log.lh.n = lh->n;
    8000422c:	4d3c                	lw	a5,88(a0)
    8000422e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004230:	02f05563          	blez	a5,8000425a <initlog+0x74>
    80004234:	05c50713          	addi	a4,a0,92
    80004238:	0001e697          	auipc	a3,0x1e
    8000423c:	88868693          	addi	a3,a3,-1912 # 80021ac0 <log+0x30>
    80004240:	37fd                	addiw	a5,a5,-1
    80004242:	1782                	slli	a5,a5,0x20
    80004244:	9381                	srli	a5,a5,0x20
    80004246:	078a                	slli	a5,a5,0x2
    80004248:	06050613          	addi	a2,a0,96
    8000424c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000424e:	4310                	lw	a2,0(a4)
    80004250:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004252:	0711                	addi	a4,a4,4
    80004254:	0691                	addi	a3,a3,4
    80004256:	fef71ce3          	bne	a4,a5,8000424e <initlog+0x68>
  brelse(buf);
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	f8c080e7          	jalr	-116(ra) # 800031e6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004262:	4505                	li	a0,1
    80004264:	00000097          	auipc	ra,0x0
    80004268:	ebe080e7          	jalr	-322(ra) # 80004122 <install_trans>
  log.lh.n = 0;
    8000426c:	0001e797          	auipc	a5,0x1e
    80004270:	8407a823          	sw	zero,-1968(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    80004274:	00000097          	auipc	ra,0x0
    80004278:	e34080e7          	jalr	-460(ra) # 800040a8 <write_head>
}
    8000427c:	70a2                	ld	ra,40(sp)
    8000427e:	7402                	ld	s0,32(sp)
    80004280:	64e2                	ld	s1,24(sp)
    80004282:	6942                	ld	s2,16(sp)
    80004284:	69a2                	ld	s3,8(sp)
    80004286:	6145                	addi	sp,sp,48
    80004288:	8082                	ret

000000008000428a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000428a:	1101                	addi	sp,sp,-32
    8000428c:	ec06                	sd	ra,24(sp)
    8000428e:	e822                	sd	s0,16(sp)
    80004290:	e426                	sd	s1,8(sp)
    80004292:	e04a                	sd	s2,0(sp)
    80004294:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004296:	0001d517          	auipc	a0,0x1d
    8000429a:	7fa50513          	addi	a0,a0,2042 # 80021a90 <log>
    8000429e:	ffffd097          	auipc	ra,0xffffd
    800042a2:	946080e7          	jalr	-1722(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800042a6:	0001d497          	auipc	s1,0x1d
    800042aa:	7ea48493          	addi	s1,s1,2026 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042ae:	4979                	li	s2,30
    800042b0:	a039                	j	800042be <begin_op+0x34>
      sleep(&log, &log.lock);
    800042b2:	85a6                	mv	a1,s1
    800042b4:	8526                	mv	a0,s1
    800042b6:	ffffe097          	auipc	ra,0xffffe
    800042ba:	fd0080e7          	jalr	-48(ra) # 80002286 <sleep>
    if(log.committing){
    800042be:	50dc                	lw	a5,36(s1)
    800042c0:	fbed                	bnez	a5,800042b2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042c2:	509c                	lw	a5,32(s1)
    800042c4:	0017871b          	addiw	a4,a5,1
    800042c8:	0007069b          	sext.w	a3,a4
    800042cc:	0027179b          	slliw	a5,a4,0x2
    800042d0:	9fb9                	addw	a5,a5,a4
    800042d2:	0017979b          	slliw	a5,a5,0x1
    800042d6:	54d8                	lw	a4,44(s1)
    800042d8:	9fb9                	addw	a5,a5,a4
    800042da:	00f95963          	bge	s2,a5,800042ec <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042de:	85a6                	mv	a1,s1
    800042e0:	8526                	mv	a0,s1
    800042e2:	ffffe097          	auipc	ra,0xffffe
    800042e6:	fa4080e7          	jalr	-92(ra) # 80002286 <sleep>
    800042ea:	bfd1                	j	800042be <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042ec:	0001d517          	auipc	a0,0x1d
    800042f0:	7a450513          	addi	a0,a0,1956 # 80021a90 <log>
    800042f4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	9a2080e7          	jalr	-1630(ra) # 80000c98 <release>
      break;
    }
  }
}
    800042fe:	60e2                	ld	ra,24(sp)
    80004300:	6442                	ld	s0,16(sp)
    80004302:	64a2                	ld	s1,8(sp)
    80004304:	6902                	ld	s2,0(sp)
    80004306:	6105                	addi	sp,sp,32
    80004308:	8082                	ret

000000008000430a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000430a:	7139                	addi	sp,sp,-64
    8000430c:	fc06                	sd	ra,56(sp)
    8000430e:	f822                	sd	s0,48(sp)
    80004310:	f426                	sd	s1,40(sp)
    80004312:	f04a                	sd	s2,32(sp)
    80004314:	ec4e                	sd	s3,24(sp)
    80004316:	e852                	sd	s4,16(sp)
    80004318:	e456                	sd	s5,8(sp)
    8000431a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000431c:	0001d497          	auipc	s1,0x1d
    80004320:	77448493          	addi	s1,s1,1908 # 80021a90 <log>
    80004324:	8526                	mv	a0,s1
    80004326:	ffffd097          	auipc	ra,0xffffd
    8000432a:	8be080e7          	jalr	-1858(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000432e:	509c                	lw	a5,32(s1)
    80004330:	37fd                	addiw	a5,a5,-1
    80004332:	0007891b          	sext.w	s2,a5
    80004336:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004338:	50dc                	lw	a5,36(s1)
    8000433a:	efb9                	bnez	a5,80004398 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000433c:	06091663          	bnez	s2,800043a8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004340:	0001d497          	auipc	s1,0x1d
    80004344:	75048493          	addi	s1,s1,1872 # 80021a90 <log>
    80004348:	4785                	li	a5,1
    8000434a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000434c:	8526                	mv	a0,s1
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	94a080e7          	jalr	-1718(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004356:	54dc                	lw	a5,44(s1)
    80004358:	06f04763          	bgtz	a5,800043c6 <end_op+0xbc>
    acquire(&log.lock);
    8000435c:	0001d497          	auipc	s1,0x1d
    80004360:	73448493          	addi	s1,s1,1844 # 80021a90 <log>
    80004364:	8526                	mv	a0,s1
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	87e080e7          	jalr	-1922(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000436e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004372:	8526                	mv	a0,s1
    80004374:	ffffe097          	auipc	ra,0xffffe
    80004378:	09e080e7          	jalr	158(ra) # 80002412 <wakeup>
    release(&log.lock);
    8000437c:	8526                	mv	a0,s1
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	91a080e7          	jalr	-1766(ra) # 80000c98 <release>
}
    80004386:	70e2                	ld	ra,56(sp)
    80004388:	7442                	ld	s0,48(sp)
    8000438a:	74a2                	ld	s1,40(sp)
    8000438c:	7902                	ld	s2,32(sp)
    8000438e:	69e2                	ld	s3,24(sp)
    80004390:	6a42                	ld	s4,16(sp)
    80004392:	6aa2                	ld	s5,8(sp)
    80004394:	6121                	addi	sp,sp,64
    80004396:	8082                	ret
    panic("log.committing");
    80004398:	00004517          	auipc	a0,0x4
    8000439c:	3c850513          	addi	a0,a0,968 # 80008760 <syscalls+0x240>
    800043a0:	ffffc097          	auipc	ra,0xffffc
    800043a4:	19e080e7          	jalr	414(ra) # 8000053e <panic>
    wakeup(&log);
    800043a8:	0001d497          	auipc	s1,0x1d
    800043ac:	6e848493          	addi	s1,s1,1768 # 80021a90 <log>
    800043b0:	8526                	mv	a0,s1
    800043b2:	ffffe097          	auipc	ra,0xffffe
    800043b6:	060080e7          	jalr	96(ra) # 80002412 <wakeup>
  release(&log.lock);
    800043ba:	8526                	mv	a0,s1
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	8dc080e7          	jalr	-1828(ra) # 80000c98 <release>
  if(do_commit){
    800043c4:	b7c9                	j	80004386 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043c6:	0001da97          	auipc	s5,0x1d
    800043ca:	6faa8a93          	addi	s5,s5,1786 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043ce:	0001da17          	auipc	s4,0x1d
    800043d2:	6c2a0a13          	addi	s4,s4,1730 # 80021a90 <log>
    800043d6:	018a2583          	lw	a1,24(s4)
    800043da:	012585bb          	addw	a1,a1,s2
    800043de:	2585                	addiw	a1,a1,1
    800043e0:	028a2503          	lw	a0,40(s4)
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	cd2080e7          	jalr	-814(ra) # 800030b6 <bread>
    800043ec:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043ee:	000aa583          	lw	a1,0(s5)
    800043f2:	028a2503          	lw	a0,40(s4)
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	cc0080e7          	jalr	-832(ra) # 800030b6 <bread>
    800043fe:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004400:	40000613          	li	a2,1024
    80004404:	05850593          	addi	a1,a0,88
    80004408:	05848513          	addi	a0,s1,88
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	934080e7          	jalr	-1740(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004414:	8526                	mv	a0,s1
    80004416:	fffff097          	auipc	ra,0xfffff
    8000441a:	d92080e7          	jalr	-622(ra) # 800031a8 <bwrite>
    brelse(from);
    8000441e:	854e                	mv	a0,s3
    80004420:	fffff097          	auipc	ra,0xfffff
    80004424:	dc6080e7          	jalr	-570(ra) # 800031e6 <brelse>
    brelse(to);
    80004428:	8526                	mv	a0,s1
    8000442a:	fffff097          	auipc	ra,0xfffff
    8000442e:	dbc080e7          	jalr	-580(ra) # 800031e6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004432:	2905                	addiw	s2,s2,1
    80004434:	0a91                	addi	s5,s5,4
    80004436:	02ca2783          	lw	a5,44(s4)
    8000443a:	f8f94ee3          	blt	s2,a5,800043d6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	c6a080e7          	jalr	-918(ra) # 800040a8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004446:	4501                	li	a0,0
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	cda080e7          	jalr	-806(ra) # 80004122 <install_trans>
    log.lh.n = 0;
    80004450:	0001d797          	auipc	a5,0x1d
    80004454:	6607a623          	sw	zero,1644(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004458:	00000097          	auipc	ra,0x0
    8000445c:	c50080e7          	jalr	-944(ra) # 800040a8 <write_head>
    80004460:	bdf5                	j	8000435c <end_op+0x52>

0000000080004462 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004462:	1101                	addi	sp,sp,-32
    80004464:	ec06                	sd	ra,24(sp)
    80004466:	e822                	sd	s0,16(sp)
    80004468:	e426                	sd	s1,8(sp)
    8000446a:	e04a                	sd	s2,0(sp)
    8000446c:	1000                	addi	s0,sp,32
    8000446e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004470:	0001d917          	auipc	s2,0x1d
    80004474:	62090913          	addi	s2,s2,1568 # 80021a90 <log>
    80004478:	854a                	mv	a0,s2
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	76a080e7          	jalr	1898(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004482:	02c92603          	lw	a2,44(s2)
    80004486:	47f5                	li	a5,29
    80004488:	06c7c563          	blt	a5,a2,800044f2 <log_write+0x90>
    8000448c:	0001d797          	auipc	a5,0x1d
    80004490:	6207a783          	lw	a5,1568(a5) # 80021aac <log+0x1c>
    80004494:	37fd                	addiw	a5,a5,-1
    80004496:	04f65e63          	bge	a2,a5,800044f2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000449a:	0001d797          	auipc	a5,0x1d
    8000449e:	6167a783          	lw	a5,1558(a5) # 80021ab0 <log+0x20>
    800044a2:	06f05063          	blez	a5,80004502 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044a6:	4781                	li	a5,0
    800044a8:	06c05563          	blez	a2,80004512 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044ac:	44cc                	lw	a1,12(s1)
    800044ae:	0001d717          	auipc	a4,0x1d
    800044b2:	61270713          	addi	a4,a4,1554 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044b6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044b8:	4314                	lw	a3,0(a4)
    800044ba:	04b68c63          	beq	a3,a1,80004512 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044be:	2785                	addiw	a5,a5,1
    800044c0:	0711                	addi	a4,a4,4
    800044c2:	fef61be3          	bne	a2,a5,800044b8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044c6:	0621                	addi	a2,a2,8
    800044c8:	060a                	slli	a2,a2,0x2
    800044ca:	0001d797          	auipc	a5,0x1d
    800044ce:	5c678793          	addi	a5,a5,1478 # 80021a90 <log>
    800044d2:	963e                	add	a2,a2,a5
    800044d4:	44dc                	lw	a5,12(s1)
    800044d6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044d8:	8526                	mv	a0,s1
    800044da:	fffff097          	auipc	ra,0xfffff
    800044de:	daa080e7          	jalr	-598(ra) # 80003284 <bpin>
    log.lh.n++;
    800044e2:	0001d717          	auipc	a4,0x1d
    800044e6:	5ae70713          	addi	a4,a4,1454 # 80021a90 <log>
    800044ea:	575c                	lw	a5,44(a4)
    800044ec:	2785                	addiw	a5,a5,1
    800044ee:	d75c                	sw	a5,44(a4)
    800044f0:	a835                	j	8000452c <log_write+0xca>
    panic("too big a transaction");
    800044f2:	00004517          	auipc	a0,0x4
    800044f6:	27e50513          	addi	a0,a0,638 # 80008770 <syscalls+0x250>
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	044080e7          	jalr	68(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004502:	00004517          	auipc	a0,0x4
    80004506:	28650513          	addi	a0,a0,646 # 80008788 <syscalls+0x268>
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	034080e7          	jalr	52(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004512:	00878713          	addi	a4,a5,8
    80004516:	00271693          	slli	a3,a4,0x2
    8000451a:	0001d717          	auipc	a4,0x1d
    8000451e:	57670713          	addi	a4,a4,1398 # 80021a90 <log>
    80004522:	9736                	add	a4,a4,a3
    80004524:	44d4                	lw	a3,12(s1)
    80004526:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004528:	faf608e3          	beq	a2,a5,800044d8 <log_write+0x76>
  }
  release(&log.lock);
    8000452c:	0001d517          	auipc	a0,0x1d
    80004530:	56450513          	addi	a0,a0,1380 # 80021a90 <log>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	764080e7          	jalr	1892(ra) # 80000c98 <release>
}
    8000453c:	60e2                	ld	ra,24(sp)
    8000453e:	6442                	ld	s0,16(sp)
    80004540:	64a2                	ld	s1,8(sp)
    80004542:	6902                	ld	s2,0(sp)
    80004544:	6105                	addi	sp,sp,32
    80004546:	8082                	ret

0000000080004548 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004548:	1101                	addi	sp,sp,-32
    8000454a:	ec06                	sd	ra,24(sp)
    8000454c:	e822                	sd	s0,16(sp)
    8000454e:	e426                	sd	s1,8(sp)
    80004550:	e04a                	sd	s2,0(sp)
    80004552:	1000                	addi	s0,sp,32
    80004554:	84aa                	mv	s1,a0
    80004556:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004558:	00004597          	auipc	a1,0x4
    8000455c:	25058593          	addi	a1,a1,592 # 800087a8 <syscalls+0x288>
    80004560:	0521                	addi	a0,a0,8
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	5f2080e7          	jalr	1522(ra) # 80000b54 <initlock>
  lk->name = name;
    8000456a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000456e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004572:	0204a423          	sw	zero,40(s1)
}
    80004576:	60e2                	ld	ra,24(sp)
    80004578:	6442                	ld	s0,16(sp)
    8000457a:	64a2                	ld	s1,8(sp)
    8000457c:	6902                	ld	s2,0(sp)
    8000457e:	6105                	addi	sp,sp,32
    80004580:	8082                	ret

0000000080004582 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004582:	1101                	addi	sp,sp,-32
    80004584:	ec06                	sd	ra,24(sp)
    80004586:	e822                	sd	s0,16(sp)
    80004588:	e426                	sd	s1,8(sp)
    8000458a:	e04a                	sd	s2,0(sp)
    8000458c:	1000                	addi	s0,sp,32
    8000458e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004590:	00850913          	addi	s2,a0,8
    80004594:	854a                	mv	a0,s2
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	64e080e7          	jalr	1614(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000459e:	409c                	lw	a5,0(s1)
    800045a0:	cb89                	beqz	a5,800045b2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045a2:	85ca                	mv	a1,s2
    800045a4:	8526                	mv	a0,s1
    800045a6:	ffffe097          	auipc	ra,0xffffe
    800045aa:	ce0080e7          	jalr	-800(ra) # 80002286 <sleep>
  while (lk->locked) {
    800045ae:	409c                	lw	a5,0(s1)
    800045b0:	fbed                	bnez	a5,800045a2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045b2:	4785                	li	a5,1
    800045b4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045b6:	ffffd097          	auipc	ra,0xffffd
    800045ba:	4be080e7          	jalr	1214(ra) # 80001a74 <myproc>
    800045be:	591c                	lw	a5,48(a0)
    800045c0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045c2:	854a                	mv	a0,s2
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	6d4080e7          	jalr	1748(ra) # 80000c98 <release>
}
    800045cc:	60e2                	ld	ra,24(sp)
    800045ce:	6442                	ld	s0,16(sp)
    800045d0:	64a2                	ld	s1,8(sp)
    800045d2:	6902                	ld	s2,0(sp)
    800045d4:	6105                	addi	sp,sp,32
    800045d6:	8082                	ret

00000000800045d8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045d8:	1101                	addi	sp,sp,-32
    800045da:	ec06                	sd	ra,24(sp)
    800045dc:	e822                	sd	s0,16(sp)
    800045de:	e426                	sd	s1,8(sp)
    800045e0:	e04a                	sd	s2,0(sp)
    800045e2:	1000                	addi	s0,sp,32
    800045e4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045e6:	00850913          	addi	s2,a0,8
    800045ea:	854a                	mv	a0,s2
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	5f8080e7          	jalr	1528(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800045f4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045f8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045fc:	8526                	mv	a0,s1
    800045fe:	ffffe097          	auipc	ra,0xffffe
    80004602:	e14080e7          	jalr	-492(ra) # 80002412 <wakeup>
  release(&lk->lk);
    80004606:	854a                	mv	a0,s2
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	690080e7          	jalr	1680(ra) # 80000c98 <release>
}
    80004610:	60e2                	ld	ra,24(sp)
    80004612:	6442                	ld	s0,16(sp)
    80004614:	64a2                	ld	s1,8(sp)
    80004616:	6902                	ld	s2,0(sp)
    80004618:	6105                	addi	sp,sp,32
    8000461a:	8082                	ret

000000008000461c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000461c:	7179                	addi	sp,sp,-48
    8000461e:	f406                	sd	ra,40(sp)
    80004620:	f022                	sd	s0,32(sp)
    80004622:	ec26                	sd	s1,24(sp)
    80004624:	e84a                	sd	s2,16(sp)
    80004626:	e44e                	sd	s3,8(sp)
    80004628:	1800                	addi	s0,sp,48
    8000462a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000462c:	00850913          	addi	s2,a0,8
    80004630:	854a                	mv	a0,s2
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	5b2080e7          	jalr	1458(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000463a:	409c                	lw	a5,0(s1)
    8000463c:	ef99                	bnez	a5,8000465a <holdingsleep+0x3e>
    8000463e:	4481                	li	s1,0
  release(&lk->lk);
    80004640:	854a                	mv	a0,s2
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	656080e7          	jalr	1622(ra) # 80000c98 <release>
  return r;
}
    8000464a:	8526                	mv	a0,s1
    8000464c:	70a2                	ld	ra,40(sp)
    8000464e:	7402                	ld	s0,32(sp)
    80004650:	64e2                	ld	s1,24(sp)
    80004652:	6942                	ld	s2,16(sp)
    80004654:	69a2                	ld	s3,8(sp)
    80004656:	6145                	addi	sp,sp,48
    80004658:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000465a:	0284a983          	lw	s3,40(s1)
    8000465e:	ffffd097          	auipc	ra,0xffffd
    80004662:	416080e7          	jalr	1046(ra) # 80001a74 <myproc>
    80004666:	5904                	lw	s1,48(a0)
    80004668:	413484b3          	sub	s1,s1,s3
    8000466c:	0014b493          	seqz	s1,s1
    80004670:	bfc1                	j	80004640 <holdingsleep+0x24>

0000000080004672 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004672:	1141                	addi	sp,sp,-16
    80004674:	e406                	sd	ra,8(sp)
    80004676:	e022                	sd	s0,0(sp)
    80004678:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000467a:	00004597          	auipc	a1,0x4
    8000467e:	13e58593          	addi	a1,a1,318 # 800087b8 <syscalls+0x298>
    80004682:	0001d517          	auipc	a0,0x1d
    80004686:	55650513          	addi	a0,a0,1366 # 80021bd8 <ftable>
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	4ca080e7          	jalr	1226(ra) # 80000b54 <initlock>
}
    80004692:	60a2                	ld	ra,8(sp)
    80004694:	6402                	ld	s0,0(sp)
    80004696:	0141                	addi	sp,sp,16
    80004698:	8082                	ret

000000008000469a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000469a:	1101                	addi	sp,sp,-32
    8000469c:	ec06                	sd	ra,24(sp)
    8000469e:	e822                	sd	s0,16(sp)
    800046a0:	e426                	sd	s1,8(sp)
    800046a2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046a4:	0001d517          	auipc	a0,0x1d
    800046a8:	53450513          	addi	a0,a0,1332 # 80021bd8 <ftable>
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046b4:	0001d497          	auipc	s1,0x1d
    800046b8:	53c48493          	addi	s1,s1,1340 # 80021bf0 <ftable+0x18>
    800046bc:	0001e717          	auipc	a4,0x1e
    800046c0:	4d470713          	addi	a4,a4,1236 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    800046c4:	40dc                	lw	a5,4(s1)
    800046c6:	cf99                	beqz	a5,800046e4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046c8:	02848493          	addi	s1,s1,40
    800046cc:	fee49ce3          	bne	s1,a4,800046c4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046d0:	0001d517          	auipc	a0,0x1d
    800046d4:	50850513          	addi	a0,a0,1288 # 80021bd8 <ftable>
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	5c0080e7          	jalr	1472(ra) # 80000c98 <release>
  return 0;
    800046e0:	4481                	li	s1,0
    800046e2:	a819                	j	800046f8 <filealloc+0x5e>
      f->ref = 1;
    800046e4:	4785                	li	a5,1
    800046e6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046e8:	0001d517          	auipc	a0,0x1d
    800046ec:	4f050513          	addi	a0,a0,1264 # 80021bd8 <ftable>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	5a8080e7          	jalr	1448(ra) # 80000c98 <release>
}
    800046f8:	8526                	mv	a0,s1
    800046fa:	60e2                	ld	ra,24(sp)
    800046fc:	6442                	ld	s0,16(sp)
    800046fe:	64a2                	ld	s1,8(sp)
    80004700:	6105                	addi	sp,sp,32
    80004702:	8082                	ret

0000000080004704 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004704:	1101                	addi	sp,sp,-32
    80004706:	ec06                	sd	ra,24(sp)
    80004708:	e822                	sd	s0,16(sp)
    8000470a:	e426                	sd	s1,8(sp)
    8000470c:	1000                	addi	s0,sp,32
    8000470e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004710:	0001d517          	auipc	a0,0x1d
    80004714:	4c850513          	addi	a0,a0,1224 # 80021bd8 <ftable>
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	4cc080e7          	jalr	1228(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004720:	40dc                	lw	a5,4(s1)
    80004722:	02f05263          	blez	a5,80004746 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004726:	2785                	addiw	a5,a5,1
    80004728:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000472a:	0001d517          	auipc	a0,0x1d
    8000472e:	4ae50513          	addi	a0,a0,1198 # 80021bd8 <ftable>
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	566080e7          	jalr	1382(ra) # 80000c98 <release>
  return f;
}
    8000473a:	8526                	mv	a0,s1
    8000473c:	60e2                	ld	ra,24(sp)
    8000473e:	6442                	ld	s0,16(sp)
    80004740:	64a2                	ld	s1,8(sp)
    80004742:	6105                	addi	sp,sp,32
    80004744:	8082                	ret
    panic("filedup");
    80004746:	00004517          	auipc	a0,0x4
    8000474a:	07a50513          	addi	a0,a0,122 # 800087c0 <syscalls+0x2a0>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	df0080e7          	jalr	-528(ra) # 8000053e <panic>

0000000080004756 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004756:	7139                	addi	sp,sp,-64
    80004758:	fc06                	sd	ra,56(sp)
    8000475a:	f822                	sd	s0,48(sp)
    8000475c:	f426                	sd	s1,40(sp)
    8000475e:	f04a                	sd	s2,32(sp)
    80004760:	ec4e                	sd	s3,24(sp)
    80004762:	e852                	sd	s4,16(sp)
    80004764:	e456                	sd	s5,8(sp)
    80004766:	0080                	addi	s0,sp,64
    80004768:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000476a:	0001d517          	auipc	a0,0x1d
    8000476e:	46e50513          	addi	a0,a0,1134 # 80021bd8 <ftable>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	472080e7          	jalr	1138(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000477a:	40dc                	lw	a5,4(s1)
    8000477c:	06f05163          	blez	a5,800047de <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004780:	37fd                	addiw	a5,a5,-1
    80004782:	0007871b          	sext.w	a4,a5
    80004786:	c0dc                	sw	a5,4(s1)
    80004788:	06e04363          	bgtz	a4,800047ee <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000478c:	0004a903          	lw	s2,0(s1)
    80004790:	0094ca83          	lbu	s5,9(s1)
    80004794:	0104ba03          	ld	s4,16(s1)
    80004798:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000479c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047a0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047a4:	0001d517          	auipc	a0,0x1d
    800047a8:	43450513          	addi	a0,a0,1076 # 80021bd8 <ftable>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	4ec080e7          	jalr	1260(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800047b4:	4785                	li	a5,1
    800047b6:	04f90d63          	beq	s2,a5,80004810 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047ba:	3979                	addiw	s2,s2,-2
    800047bc:	4785                	li	a5,1
    800047be:	0527e063          	bltu	a5,s2,800047fe <fileclose+0xa8>
    begin_op();
    800047c2:	00000097          	auipc	ra,0x0
    800047c6:	ac8080e7          	jalr	-1336(ra) # 8000428a <begin_op>
    iput(ff.ip);
    800047ca:	854e                	mv	a0,s3
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	2a6080e7          	jalr	678(ra) # 80003a72 <iput>
    end_op();
    800047d4:	00000097          	auipc	ra,0x0
    800047d8:	b36080e7          	jalr	-1226(ra) # 8000430a <end_op>
    800047dc:	a00d                	j	800047fe <fileclose+0xa8>
    panic("fileclose");
    800047de:	00004517          	auipc	a0,0x4
    800047e2:	fea50513          	addi	a0,a0,-22 # 800087c8 <syscalls+0x2a8>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	d58080e7          	jalr	-680(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047ee:	0001d517          	auipc	a0,0x1d
    800047f2:	3ea50513          	addi	a0,a0,1002 # 80021bd8 <ftable>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	4a2080e7          	jalr	1186(ra) # 80000c98 <release>
  }
}
    800047fe:	70e2                	ld	ra,56(sp)
    80004800:	7442                	ld	s0,48(sp)
    80004802:	74a2                	ld	s1,40(sp)
    80004804:	7902                	ld	s2,32(sp)
    80004806:	69e2                	ld	s3,24(sp)
    80004808:	6a42                	ld	s4,16(sp)
    8000480a:	6aa2                	ld	s5,8(sp)
    8000480c:	6121                	addi	sp,sp,64
    8000480e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004810:	85d6                	mv	a1,s5
    80004812:	8552                	mv	a0,s4
    80004814:	00000097          	auipc	ra,0x0
    80004818:	34c080e7          	jalr	844(ra) # 80004b60 <pipeclose>
    8000481c:	b7cd                	j	800047fe <fileclose+0xa8>

000000008000481e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000481e:	715d                	addi	sp,sp,-80
    80004820:	e486                	sd	ra,72(sp)
    80004822:	e0a2                	sd	s0,64(sp)
    80004824:	fc26                	sd	s1,56(sp)
    80004826:	f84a                	sd	s2,48(sp)
    80004828:	f44e                	sd	s3,40(sp)
    8000482a:	0880                	addi	s0,sp,80
    8000482c:	84aa                	mv	s1,a0
    8000482e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004830:	ffffd097          	auipc	ra,0xffffd
    80004834:	244080e7          	jalr	580(ra) # 80001a74 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004838:	409c                	lw	a5,0(s1)
    8000483a:	37f9                	addiw	a5,a5,-2
    8000483c:	4705                	li	a4,1
    8000483e:	04f76763          	bltu	a4,a5,8000488c <filestat+0x6e>
    80004842:	892a                	mv	s2,a0
    ilock(f->ip);
    80004844:	6c88                	ld	a0,24(s1)
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	072080e7          	jalr	114(ra) # 800038b8 <ilock>
    stati(f->ip, &st);
    8000484e:	fb840593          	addi	a1,s0,-72
    80004852:	6c88                	ld	a0,24(s1)
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	2ee080e7          	jalr	750(ra) # 80003b42 <stati>
    iunlock(f->ip);
    8000485c:	6c88                	ld	a0,24(s1)
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	11c080e7          	jalr	284(ra) # 8000397a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004866:	46e1                	li	a3,24
    80004868:	fb840613          	addi	a2,s0,-72
    8000486c:	85ce                	mv	a1,s3
    8000486e:	05093503          	ld	a0,80(s2)
    80004872:	ffffd097          	auipc	ra,0xffffd
    80004876:	e00080e7          	jalr	-512(ra) # 80001672 <copyout>
    8000487a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000487e:	60a6                	ld	ra,72(sp)
    80004880:	6406                	ld	s0,64(sp)
    80004882:	74e2                	ld	s1,56(sp)
    80004884:	7942                	ld	s2,48(sp)
    80004886:	79a2                	ld	s3,40(sp)
    80004888:	6161                	addi	sp,sp,80
    8000488a:	8082                	ret
  return -1;
    8000488c:	557d                	li	a0,-1
    8000488e:	bfc5                	j	8000487e <filestat+0x60>

0000000080004890 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004890:	7179                	addi	sp,sp,-48
    80004892:	f406                	sd	ra,40(sp)
    80004894:	f022                	sd	s0,32(sp)
    80004896:	ec26                	sd	s1,24(sp)
    80004898:	e84a                	sd	s2,16(sp)
    8000489a:	e44e                	sd	s3,8(sp)
    8000489c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000489e:	00854783          	lbu	a5,8(a0)
    800048a2:	c3d5                	beqz	a5,80004946 <fileread+0xb6>
    800048a4:	84aa                	mv	s1,a0
    800048a6:	89ae                	mv	s3,a1
    800048a8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048aa:	411c                	lw	a5,0(a0)
    800048ac:	4705                	li	a4,1
    800048ae:	04e78963          	beq	a5,a4,80004900 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048b2:	470d                	li	a4,3
    800048b4:	04e78d63          	beq	a5,a4,8000490e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048b8:	4709                	li	a4,2
    800048ba:	06e79e63          	bne	a5,a4,80004936 <fileread+0xa6>
    ilock(f->ip);
    800048be:	6d08                	ld	a0,24(a0)
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	ff8080e7          	jalr	-8(ra) # 800038b8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048c8:	874a                	mv	a4,s2
    800048ca:	5094                	lw	a3,32(s1)
    800048cc:	864e                	mv	a2,s3
    800048ce:	4585                	li	a1,1
    800048d0:	6c88                	ld	a0,24(s1)
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	29a080e7          	jalr	666(ra) # 80003b6c <readi>
    800048da:	892a                	mv	s2,a0
    800048dc:	00a05563          	blez	a0,800048e6 <fileread+0x56>
      f->off += r;
    800048e0:	509c                	lw	a5,32(s1)
    800048e2:	9fa9                	addw	a5,a5,a0
    800048e4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048e6:	6c88                	ld	a0,24(s1)
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	092080e7          	jalr	146(ra) # 8000397a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048f0:	854a                	mv	a0,s2
    800048f2:	70a2                	ld	ra,40(sp)
    800048f4:	7402                	ld	s0,32(sp)
    800048f6:	64e2                	ld	s1,24(sp)
    800048f8:	6942                	ld	s2,16(sp)
    800048fa:	69a2                	ld	s3,8(sp)
    800048fc:	6145                	addi	sp,sp,48
    800048fe:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004900:	6908                	ld	a0,16(a0)
    80004902:	00000097          	auipc	ra,0x0
    80004906:	3c8080e7          	jalr	968(ra) # 80004cca <piperead>
    8000490a:	892a                	mv	s2,a0
    8000490c:	b7d5                	j	800048f0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000490e:	02451783          	lh	a5,36(a0)
    80004912:	03079693          	slli	a3,a5,0x30
    80004916:	92c1                	srli	a3,a3,0x30
    80004918:	4725                	li	a4,9
    8000491a:	02d76863          	bltu	a4,a3,8000494a <fileread+0xba>
    8000491e:	0792                	slli	a5,a5,0x4
    80004920:	0001d717          	auipc	a4,0x1d
    80004924:	21870713          	addi	a4,a4,536 # 80021b38 <devsw>
    80004928:	97ba                	add	a5,a5,a4
    8000492a:	639c                	ld	a5,0(a5)
    8000492c:	c38d                	beqz	a5,8000494e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000492e:	4505                	li	a0,1
    80004930:	9782                	jalr	a5
    80004932:	892a                	mv	s2,a0
    80004934:	bf75                	j	800048f0 <fileread+0x60>
    panic("fileread");
    80004936:	00004517          	auipc	a0,0x4
    8000493a:	ea250513          	addi	a0,a0,-350 # 800087d8 <syscalls+0x2b8>
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	c00080e7          	jalr	-1024(ra) # 8000053e <panic>
    return -1;
    80004946:	597d                	li	s2,-1
    80004948:	b765                	j	800048f0 <fileread+0x60>
      return -1;
    8000494a:	597d                	li	s2,-1
    8000494c:	b755                	j	800048f0 <fileread+0x60>
    8000494e:	597d                	li	s2,-1
    80004950:	b745                	j	800048f0 <fileread+0x60>

0000000080004952 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004952:	715d                	addi	sp,sp,-80
    80004954:	e486                	sd	ra,72(sp)
    80004956:	e0a2                	sd	s0,64(sp)
    80004958:	fc26                	sd	s1,56(sp)
    8000495a:	f84a                	sd	s2,48(sp)
    8000495c:	f44e                	sd	s3,40(sp)
    8000495e:	f052                	sd	s4,32(sp)
    80004960:	ec56                	sd	s5,24(sp)
    80004962:	e85a                	sd	s6,16(sp)
    80004964:	e45e                	sd	s7,8(sp)
    80004966:	e062                	sd	s8,0(sp)
    80004968:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000496a:	00954783          	lbu	a5,9(a0)
    8000496e:	10078663          	beqz	a5,80004a7a <filewrite+0x128>
    80004972:	892a                	mv	s2,a0
    80004974:	8aae                	mv	s5,a1
    80004976:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004978:	411c                	lw	a5,0(a0)
    8000497a:	4705                	li	a4,1
    8000497c:	02e78263          	beq	a5,a4,800049a0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004980:	470d                	li	a4,3
    80004982:	02e78663          	beq	a5,a4,800049ae <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004986:	4709                	li	a4,2
    80004988:	0ee79163          	bne	a5,a4,80004a6a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000498c:	0ac05d63          	blez	a2,80004a46 <filewrite+0xf4>
    int i = 0;
    80004990:	4981                	li	s3,0
    80004992:	6b05                	lui	s6,0x1
    80004994:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004998:	6b85                	lui	s7,0x1
    8000499a:	c00b8b9b          	addiw	s7,s7,-1024
    8000499e:	a861                	j	80004a36 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049a0:	6908                	ld	a0,16(a0)
    800049a2:	00000097          	auipc	ra,0x0
    800049a6:	22e080e7          	jalr	558(ra) # 80004bd0 <pipewrite>
    800049aa:	8a2a                	mv	s4,a0
    800049ac:	a045                	j	80004a4c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049ae:	02451783          	lh	a5,36(a0)
    800049b2:	03079693          	slli	a3,a5,0x30
    800049b6:	92c1                	srli	a3,a3,0x30
    800049b8:	4725                	li	a4,9
    800049ba:	0cd76263          	bltu	a4,a3,80004a7e <filewrite+0x12c>
    800049be:	0792                	slli	a5,a5,0x4
    800049c0:	0001d717          	auipc	a4,0x1d
    800049c4:	17870713          	addi	a4,a4,376 # 80021b38 <devsw>
    800049c8:	97ba                	add	a5,a5,a4
    800049ca:	679c                	ld	a5,8(a5)
    800049cc:	cbdd                	beqz	a5,80004a82 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049ce:	4505                	li	a0,1
    800049d0:	9782                	jalr	a5
    800049d2:	8a2a                	mv	s4,a0
    800049d4:	a8a5                	j	80004a4c <filewrite+0xfa>
    800049d6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049da:	00000097          	auipc	ra,0x0
    800049de:	8b0080e7          	jalr	-1872(ra) # 8000428a <begin_op>
      ilock(f->ip);
    800049e2:	01893503          	ld	a0,24(s2)
    800049e6:	fffff097          	auipc	ra,0xfffff
    800049ea:	ed2080e7          	jalr	-302(ra) # 800038b8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049ee:	8762                	mv	a4,s8
    800049f0:	02092683          	lw	a3,32(s2)
    800049f4:	01598633          	add	a2,s3,s5
    800049f8:	4585                	li	a1,1
    800049fa:	01893503          	ld	a0,24(s2)
    800049fe:	fffff097          	auipc	ra,0xfffff
    80004a02:	266080e7          	jalr	614(ra) # 80003c64 <writei>
    80004a06:	84aa                	mv	s1,a0
    80004a08:	00a05763          	blez	a0,80004a16 <filewrite+0xc4>
        f->off += r;
    80004a0c:	02092783          	lw	a5,32(s2)
    80004a10:	9fa9                	addw	a5,a5,a0
    80004a12:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a16:	01893503          	ld	a0,24(s2)
    80004a1a:	fffff097          	auipc	ra,0xfffff
    80004a1e:	f60080e7          	jalr	-160(ra) # 8000397a <iunlock>
      end_op();
    80004a22:	00000097          	auipc	ra,0x0
    80004a26:	8e8080e7          	jalr	-1816(ra) # 8000430a <end_op>

      if(r != n1){
    80004a2a:	009c1f63          	bne	s8,s1,80004a48 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a2e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a32:	0149db63          	bge	s3,s4,80004a48 <filewrite+0xf6>
      int n1 = n - i;
    80004a36:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a3a:	84be                	mv	s1,a5
    80004a3c:	2781                	sext.w	a5,a5
    80004a3e:	f8fb5ce3          	bge	s6,a5,800049d6 <filewrite+0x84>
    80004a42:	84de                	mv	s1,s7
    80004a44:	bf49                	j	800049d6 <filewrite+0x84>
    int i = 0;
    80004a46:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a48:	013a1f63          	bne	s4,s3,80004a66 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a4c:	8552                	mv	a0,s4
    80004a4e:	60a6                	ld	ra,72(sp)
    80004a50:	6406                	ld	s0,64(sp)
    80004a52:	74e2                	ld	s1,56(sp)
    80004a54:	7942                	ld	s2,48(sp)
    80004a56:	79a2                	ld	s3,40(sp)
    80004a58:	7a02                	ld	s4,32(sp)
    80004a5a:	6ae2                	ld	s5,24(sp)
    80004a5c:	6b42                	ld	s6,16(sp)
    80004a5e:	6ba2                	ld	s7,8(sp)
    80004a60:	6c02                	ld	s8,0(sp)
    80004a62:	6161                	addi	sp,sp,80
    80004a64:	8082                	ret
    ret = (i == n ? n : -1);
    80004a66:	5a7d                	li	s4,-1
    80004a68:	b7d5                	j	80004a4c <filewrite+0xfa>
    panic("filewrite");
    80004a6a:	00004517          	auipc	a0,0x4
    80004a6e:	d7e50513          	addi	a0,a0,-642 # 800087e8 <syscalls+0x2c8>
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	acc080e7          	jalr	-1332(ra) # 8000053e <panic>
    return -1;
    80004a7a:	5a7d                	li	s4,-1
    80004a7c:	bfc1                	j	80004a4c <filewrite+0xfa>
      return -1;
    80004a7e:	5a7d                	li	s4,-1
    80004a80:	b7f1                	j	80004a4c <filewrite+0xfa>
    80004a82:	5a7d                	li	s4,-1
    80004a84:	b7e1                	j	80004a4c <filewrite+0xfa>

0000000080004a86 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a86:	7179                	addi	sp,sp,-48
    80004a88:	f406                	sd	ra,40(sp)
    80004a8a:	f022                	sd	s0,32(sp)
    80004a8c:	ec26                	sd	s1,24(sp)
    80004a8e:	e84a                	sd	s2,16(sp)
    80004a90:	e44e                	sd	s3,8(sp)
    80004a92:	e052                	sd	s4,0(sp)
    80004a94:	1800                	addi	s0,sp,48
    80004a96:	84aa                	mv	s1,a0
    80004a98:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a9a:	0005b023          	sd	zero,0(a1)
    80004a9e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	bf8080e7          	jalr	-1032(ra) # 8000469a <filealloc>
    80004aaa:	e088                	sd	a0,0(s1)
    80004aac:	c551                	beqz	a0,80004b38 <pipealloc+0xb2>
    80004aae:	00000097          	auipc	ra,0x0
    80004ab2:	bec080e7          	jalr	-1044(ra) # 8000469a <filealloc>
    80004ab6:	00aa3023          	sd	a0,0(s4)
    80004aba:	c92d                	beqz	a0,80004b2c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	038080e7          	jalr	56(ra) # 80000af4 <kalloc>
    80004ac4:	892a                	mv	s2,a0
    80004ac6:	c125                	beqz	a0,80004b26 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ac8:	4985                	li	s3,1
    80004aca:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ace:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ad2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ad6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ada:	00004597          	auipc	a1,0x4
    80004ade:	d1e58593          	addi	a1,a1,-738 # 800087f8 <syscalls+0x2d8>
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	072080e7          	jalr	114(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004aea:	609c                	ld	a5,0(s1)
    80004aec:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004af0:	609c                	ld	a5,0(s1)
    80004af2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004af6:	609c                	ld	a5,0(s1)
    80004af8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004afc:	609c                	ld	a5,0(s1)
    80004afe:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b02:	000a3783          	ld	a5,0(s4)
    80004b06:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b0a:	000a3783          	ld	a5,0(s4)
    80004b0e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b12:	000a3783          	ld	a5,0(s4)
    80004b16:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b1a:	000a3783          	ld	a5,0(s4)
    80004b1e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b22:	4501                	li	a0,0
    80004b24:	a025                	j	80004b4c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b26:	6088                	ld	a0,0(s1)
    80004b28:	e501                	bnez	a0,80004b30 <pipealloc+0xaa>
    80004b2a:	a039                	j	80004b38 <pipealloc+0xb2>
    80004b2c:	6088                	ld	a0,0(s1)
    80004b2e:	c51d                	beqz	a0,80004b5c <pipealloc+0xd6>
    fileclose(*f0);
    80004b30:	00000097          	auipc	ra,0x0
    80004b34:	c26080e7          	jalr	-986(ra) # 80004756 <fileclose>
  if(*f1)
    80004b38:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b3c:	557d                	li	a0,-1
  if(*f1)
    80004b3e:	c799                	beqz	a5,80004b4c <pipealloc+0xc6>
    fileclose(*f1);
    80004b40:	853e                	mv	a0,a5
    80004b42:	00000097          	auipc	ra,0x0
    80004b46:	c14080e7          	jalr	-1004(ra) # 80004756 <fileclose>
  return -1;
    80004b4a:	557d                	li	a0,-1
}
    80004b4c:	70a2                	ld	ra,40(sp)
    80004b4e:	7402                	ld	s0,32(sp)
    80004b50:	64e2                	ld	s1,24(sp)
    80004b52:	6942                	ld	s2,16(sp)
    80004b54:	69a2                	ld	s3,8(sp)
    80004b56:	6a02                	ld	s4,0(sp)
    80004b58:	6145                	addi	sp,sp,48
    80004b5a:	8082                	ret
  return -1;
    80004b5c:	557d                	li	a0,-1
    80004b5e:	b7fd                	j	80004b4c <pipealloc+0xc6>

0000000080004b60 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b60:	1101                	addi	sp,sp,-32
    80004b62:	ec06                	sd	ra,24(sp)
    80004b64:	e822                	sd	s0,16(sp)
    80004b66:	e426                	sd	s1,8(sp)
    80004b68:	e04a                	sd	s2,0(sp)
    80004b6a:	1000                	addi	s0,sp,32
    80004b6c:	84aa                	mv	s1,a0
    80004b6e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	074080e7          	jalr	116(ra) # 80000be4 <acquire>
  if(writable){
    80004b78:	02090d63          	beqz	s2,80004bb2 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b7c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b80:	21848513          	addi	a0,s1,536
    80004b84:	ffffe097          	auipc	ra,0xffffe
    80004b88:	88e080e7          	jalr	-1906(ra) # 80002412 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b8c:	2204b783          	ld	a5,544(s1)
    80004b90:	eb95                	bnez	a5,80004bc4 <pipeclose+0x64>
    release(&pi->lock);
    80004b92:	8526                	mv	a0,s1
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	104080e7          	jalr	260(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	e5a080e7          	jalr	-422(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004ba6:	60e2                	ld	ra,24(sp)
    80004ba8:	6442                	ld	s0,16(sp)
    80004baa:	64a2                	ld	s1,8(sp)
    80004bac:	6902                	ld	s2,0(sp)
    80004bae:	6105                	addi	sp,sp,32
    80004bb0:	8082                	ret
    pi->readopen = 0;
    80004bb2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bb6:	21c48513          	addi	a0,s1,540
    80004bba:	ffffe097          	auipc	ra,0xffffe
    80004bbe:	858080e7          	jalr	-1960(ra) # 80002412 <wakeup>
    80004bc2:	b7e9                	j	80004b8c <pipeclose+0x2c>
    release(&pi->lock);
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	0d2080e7          	jalr	210(ra) # 80000c98 <release>
}
    80004bce:	bfe1                	j	80004ba6 <pipeclose+0x46>

0000000080004bd0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bd0:	7159                	addi	sp,sp,-112
    80004bd2:	f486                	sd	ra,104(sp)
    80004bd4:	f0a2                	sd	s0,96(sp)
    80004bd6:	eca6                	sd	s1,88(sp)
    80004bd8:	e8ca                	sd	s2,80(sp)
    80004bda:	e4ce                	sd	s3,72(sp)
    80004bdc:	e0d2                	sd	s4,64(sp)
    80004bde:	fc56                	sd	s5,56(sp)
    80004be0:	f85a                	sd	s6,48(sp)
    80004be2:	f45e                	sd	s7,40(sp)
    80004be4:	f062                	sd	s8,32(sp)
    80004be6:	ec66                	sd	s9,24(sp)
    80004be8:	1880                	addi	s0,sp,112
    80004bea:	84aa                	mv	s1,a0
    80004bec:	8aae                	mv	s5,a1
    80004bee:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bf0:	ffffd097          	auipc	ra,0xffffd
    80004bf4:	e84080e7          	jalr	-380(ra) # 80001a74 <myproc>
    80004bf8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fe8080e7          	jalr	-24(ra) # 80000be4 <acquire>
  while(i < n){
    80004c04:	0d405163          	blez	s4,80004cc6 <pipewrite+0xf6>
    80004c08:	8ba6                	mv	s7,s1
  int i = 0;
    80004c0a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c0c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c0e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c12:	21c48c13          	addi	s8,s1,540
    80004c16:	a08d                	j	80004c78 <pipewrite+0xa8>
      release(&pi->lock);
    80004c18:	8526                	mv	a0,s1
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	07e080e7          	jalr	126(ra) # 80000c98 <release>
      return -1;
    80004c22:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c24:	854a                	mv	a0,s2
    80004c26:	70a6                	ld	ra,104(sp)
    80004c28:	7406                	ld	s0,96(sp)
    80004c2a:	64e6                	ld	s1,88(sp)
    80004c2c:	6946                	ld	s2,80(sp)
    80004c2e:	69a6                	ld	s3,72(sp)
    80004c30:	6a06                	ld	s4,64(sp)
    80004c32:	7ae2                	ld	s5,56(sp)
    80004c34:	7b42                	ld	s6,48(sp)
    80004c36:	7ba2                	ld	s7,40(sp)
    80004c38:	7c02                	ld	s8,32(sp)
    80004c3a:	6ce2                	ld	s9,24(sp)
    80004c3c:	6165                	addi	sp,sp,112
    80004c3e:	8082                	ret
      wakeup(&pi->nread);
    80004c40:	8566                	mv	a0,s9
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	7d0080e7          	jalr	2000(ra) # 80002412 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c4a:	85de                	mv	a1,s7
    80004c4c:	8562                	mv	a0,s8
    80004c4e:	ffffd097          	auipc	ra,0xffffd
    80004c52:	638080e7          	jalr	1592(ra) # 80002286 <sleep>
    80004c56:	a839                	j	80004c74 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c58:	21c4a783          	lw	a5,540(s1)
    80004c5c:	0017871b          	addiw	a4,a5,1
    80004c60:	20e4ae23          	sw	a4,540(s1)
    80004c64:	1ff7f793          	andi	a5,a5,511
    80004c68:	97a6                	add	a5,a5,s1
    80004c6a:	f9f44703          	lbu	a4,-97(s0)
    80004c6e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c72:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c74:	03495d63          	bge	s2,s4,80004cae <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c78:	2204a783          	lw	a5,544(s1)
    80004c7c:	dfd1                	beqz	a5,80004c18 <pipewrite+0x48>
    80004c7e:	0289a783          	lw	a5,40(s3)
    80004c82:	fbd9                	bnez	a5,80004c18 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c84:	2184a783          	lw	a5,536(s1)
    80004c88:	21c4a703          	lw	a4,540(s1)
    80004c8c:	2007879b          	addiw	a5,a5,512
    80004c90:	faf708e3          	beq	a4,a5,80004c40 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c94:	4685                	li	a3,1
    80004c96:	01590633          	add	a2,s2,s5
    80004c9a:	f9f40593          	addi	a1,s0,-97
    80004c9e:	0509b503          	ld	a0,80(s3)
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	a5c080e7          	jalr	-1444(ra) # 800016fe <copyin>
    80004caa:	fb6517e3          	bne	a0,s6,80004c58 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cae:	21848513          	addi	a0,s1,536
    80004cb2:	ffffd097          	auipc	ra,0xffffd
    80004cb6:	760080e7          	jalr	1888(ra) # 80002412 <wakeup>
  release(&pi->lock);
    80004cba:	8526                	mv	a0,s1
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	fdc080e7          	jalr	-36(ra) # 80000c98 <release>
  return i;
    80004cc4:	b785                	j	80004c24 <pipewrite+0x54>
  int i = 0;
    80004cc6:	4901                	li	s2,0
    80004cc8:	b7dd                	j	80004cae <pipewrite+0xde>

0000000080004cca <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cca:	715d                	addi	sp,sp,-80
    80004ccc:	e486                	sd	ra,72(sp)
    80004cce:	e0a2                	sd	s0,64(sp)
    80004cd0:	fc26                	sd	s1,56(sp)
    80004cd2:	f84a                	sd	s2,48(sp)
    80004cd4:	f44e                	sd	s3,40(sp)
    80004cd6:	f052                	sd	s4,32(sp)
    80004cd8:	ec56                	sd	s5,24(sp)
    80004cda:	e85a                	sd	s6,16(sp)
    80004cdc:	0880                	addi	s0,sp,80
    80004cde:	84aa                	mv	s1,a0
    80004ce0:	892e                	mv	s2,a1
    80004ce2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	d90080e7          	jalr	-624(ra) # 80001a74 <myproc>
    80004cec:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cee:	8b26                	mv	s6,s1
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	ef2080e7          	jalr	-270(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cfa:	2184a703          	lw	a4,536(s1)
    80004cfe:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d02:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d06:	02f71463          	bne	a4,a5,80004d2e <piperead+0x64>
    80004d0a:	2244a783          	lw	a5,548(s1)
    80004d0e:	c385                	beqz	a5,80004d2e <piperead+0x64>
    if(pr->killed){
    80004d10:	028a2783          	lw	a5,40(s4)
    80004d14:	ebc1                	bnez	a5,80004da4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d16:	85da                	mv	a1,s6
    80004d18:	854e                	mv	a0,s3
    80004d1a:	ffffd097          	auipc	ra,0xffffd
    80004d1e:	56c080e7          	jalr	1388(ra) # 80002286 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d22:	2184a703          	lw	a4,536(s1)
    80004d26:	21c4a783          	lw	a5,540(s1)
    80004d2a:	fef700e3          	beq	a4,a5,80004d0a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d2e:	09505263          	blez	s5,80004db2 <piperead+0xe8>
    80004d32:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d34:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d36:	2184a783          	lw	a5,536(s1)
    80004d3a:	21c4a703          	lw	a4,540(s1)
    80004d3e:	02f70d63          	beq	a4,a5,80004d78 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d42:	0017871b          	addiw	a4,a5,1
    80004d46:	20e4ac23          	sw	a4,536(s1)
    80004d4a:	1ff7f793          	andi	a5,a5,511
    80004d4e:	97a6                	add	a5,a5,s1
    80004d50:	0187c783          	lbu	a5,24(a5)
    80004d54:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d58:	4685                	li	a3,1
    80004d5a:	fbf40613          	addi	a2,s0,-65
    80004d5e:	85ca                	mv	a1,s2
    80004d60:	050a3503          	ld	a0,80(s4)
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	90e080e7          	jalr	-1778(ra) # 80001672 <copyout>
    80004d6c:	01650663          	beq	a0,s6,80004d78 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d70:	2985                	addiw	s3,s3,1
    80004d72:	0905                	addi	s2,s2,1
    80004d74:	fd3a91e3          	bne	s5,s3,80004d36 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d78:	21c48513          	addi	a0,s1,540
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	696080e7          	jalr	1686(ra) # 80002412 <wakeup>
  release(&pi->lock);
    80004d84:	8526                	mv	a0,s1
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	f12080e7          	jalr	-238(ra) # 80000c98 <release>
  return i;
}
    80004d8e:	854e                	mv	a0,s3
    80004d90:	60a6                	ld	ra,72(sp)
    80004d92:	6406                	ld	s0,64(sp)
    80004d94:	74e2                	ld	s1,56(sp)
    80004d96:	7942                	ld	s2,48(sp)
    80004d98:	79a2                	ld	s3,40(sp)
    80004d9a:	7a02                	ld	s4,32(sp)
    80004d9c:	6ae2                	ld	s5,24(sp)
    80004d9e:	6b42                	ld	s6,16(sp)
    80004da0:	6161                	addi	sp,sp,80
    80004da2:	8082                	ret
      release(&pi->lock);
    80004da4:	8526                	mv	a0,s1
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	ef2080e7          	jalr	-270(ra) # 80000c98 <release>
      return -1;
    80004dae:	59fd                	li	s3,-1
    80004db0:	bff9                	j	80004d8e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004db2:	4981                	li	s3,0
    80004db4:	b7d1                	j	80004d78 <piperead+0xae>

0000000080004db6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004db6:	df010113          	addi	sp,sp,-528
    80004dba:	20113423          	sd	ra,520(sp)
    80004dbe:	20813023          	sd	s0,512(sp)
    80004dc2:	ffa6                	sd	s1,504(sp)
    80004dc4:	fbca                	sd	s2,496(sp)
    80004dc6:	f7ce                	sd	s3,488(sp)
    80004dc8:	f3d2                	sd	s4,480(sp)
    80004dca:	efd6                	sd	s5,472(sp)
    80004dcc:	ebda                	sd	s6,464(sp)
    80004dce:	e7de                	sd	s7,456(sp)
    80004dd0:	e3e2                	sd	s8,448(sp)
    80004dd2:	ff66                	sd	s9,440(sp)
    80004dd4:	fb6a                	sd	s10,432(sp)
    80004dd6:	f76e                	sd	s11,424(sp)
    80004dd8:	0c00                	addi	s0,sp,528
    80004dda:	84aa                	mv	s1,a0
    80004ddc:	dea43c23          	sd	a0,-520(s0)
    80004de0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	c90080e7          	jalr	-880(ra) # 80001a74 <myproc>
    80004dec:	892a                	mv	s2,a0

  begin_op();
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	49c080e7          	jalr	1180(ra) # 8000428a <begin_op>

  if((ip = namei(path)) == 0){
    80004df6:	8526                	mv	a0,s1
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	276080e7          	jalr	630(ra) # 8000406e <namei>
    80004e00:	c92d                	beqz	a0,80004e72 <exec+0xbc>
    80004e02:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	ab4080e7          	jalr	-1356(ra) # 800038b8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e0c:	04000713          	li	a4,64
    80004e10:	4681                	li	a3,0
    80004e12:	e5040613          	addi	a2,s0,-432
    80004e16:	4581                	li	a1,0
    80004e18:	8526                	mv	a0,s1
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	d52080e7          	jalr	-686(ra) # 80003b6c <readi>
    80004e22:	04000793          	li	a5,64
    80004e26:	00f51a63          	bne	a0,a5,80004e3a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e2a:	e5042703          	lw	a4,-432(s0)
    80004e2e:	464c47b7          	lui	a5,0x464c4
    80004e32:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e36:	04f70463          	beq	a4,a5,80004e7e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e3a:	8526                	mv	a0,s1
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	cde080e7          	jalr	-802(ra) # 80003b1a <iunlockput>
    end_op();
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	4c6080e7          	jalr	1222(ra) # 8000430a <end_op>
  }
  return -1;
    80004e4c:	557d                	li	a0,-1
}
    80004e4e:	20813083          	ld	ra,520(sp)
    80004e52:	20013403          	ld	s0,512(sp)
    80004e56:	74fe                	ld	s1,504(sp)
    80004e58:	795e                	ld	s2,496(sp)
    80004e5a:	79be                	ld	s3,488(sp)
    80004e5c:	7a1e                	ld	s4,480(sp)
    80004e5e:	6afe                	ld	s5,472(sp)
    80004e60:	6b5e                	ld	s6,464(sp)
    80004e62:	6bbe                	ld	s7,456(sp)
    80004e64:	6c1e                	ld	s8,448(sp)
    80004e66:	7cfa                	ld	s9,440(sp)
    80004e68:	7d5a                	ld	s10,432(sp)
    80004e6a:	7dba                	ld	s11,424(sp)
    80004e6c:	21010113          	addi	sp,sp,528
    80004e70:	8082                	ret
    end_op();
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	498080e7          	jalr	1176(ra) # 8000430a <end_op>
    return -1;
    80004e7a:	557d                	li	a0,-1
    80004e7c:	bfc9                	j	80004e4e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e7e:	854a                	mv	a0,s2
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	ce4080e7          	jalr	-796(ra) # 80001b64 <proc_pagetable>
    80004e88:	8baa                	mv	s7,a0
    80004e8a:	d945                	beqz	a0,80004e3a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e8c:	e7042983          	lw	s3,-400(s0)
    80004e90:	e8845783          	lhu	a5,-376(s0)
    80004e94:	c7ad                	beqz	a5,80004efe <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e96:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e98:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e9a:	6c85                	lui	s9,0x1
    80004e9c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ea0:	def43823          	sd	a5,-528(s0)
    80004ea4:	a42d                	j	800050ce <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ea6:	00004517          	auipc	a0,0x4
    80004eaa:	95a50513          	addi	a0,a0,-1702 # 80008800 <syscalls+0x2e0>
    80004eae:	ffffb097          	auipc	ra,0xffffb
    80004eb2:	690080e7          	jalr	1680(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eb6:	8756                	mv	a4,s5
    80004eb8:	012d86bb          	addw	a3,s11,s2
    80004ebc:	4581                	li	a1,0
    80004ebe:	8526                	mv	a0,s1
    80004ec0:	fffff097          	auipc	ra,0xfffff
    80004ec4:	cac080e7          	jalr	-852(ra) # 80003b6c <readi>
    80004ec8:	2501                	sext.w	a0,a0
    80004eca:	1aaa9963          	bne	s5,a0,8000507c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ece:	6785                	lui	a5,0x1
    80004ed0:	0127893b          	addw	s2,a5,s2
    80004ed4:	77fd                	lui	a5,0xfffff
    80004ed6:	01478a3b          	addw	s4,a5,s4
    80004eda:	1f897163          	bgeu	s2,s8,800050bc <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ede:	02091593          	slli	a1,s2,0x20
    80004ee2:	9181                	srli	a1,a1,0x20
    80004ee4:	95ea                	add	a1,a1,s10
    80004ee6:	855e                	mv	a0,s7
    80004ee8:	ffffc097          	auipc	ra,0xffffc
    80004eec:	186080e7          	jalr	390(ra) # 8000106e <walkaddr>
    80004ef0:	862a                	mv	a2,a0
    if(pa == 0)
    80004ef2:	d955                	beqz	a0,80004ea6 <exec+0xf0>
      n = PGSIZE;
    80004ef4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ef6:	fd9a70e3          	bgeu	s4,s9,80004eb6 <exec+0x100>
      n = sz - i;
    80004efa:	8ad2                	mv	s5,s4
    80004efc:	bf6d                	j	80004eb6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004efe:	4901                	li	s2,0
  iunlockput(ip);
    80004f00:	8526                	mv	a0,s1
    80004f02:	fffff097          	auipc	ra,0xfffff
    80004f06:	c18080e7          	jalr	-1000(ra) # 80003b1a <iunlockput>
  end_op();
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	400080e7          	jalr	1024(ra) # 8000430a <end_op>
  p = myproc();
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	b62080e7          	jalr	-1182(ra) # 80001a74 <myproc>
    80004f1a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f1c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f20:	6785                	lui	a5,0x1
    80004f22:	17fd                	addi	a5,a5,-1
    80004f24:	993e                	add	s2,s2,a5
    80004f26:	757d                	lui	a0,0xfffff
    80004f28:	00a977b3          	and	a5,s2,a0
    80004f2c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f30:	6609                	lui	a2,0x2
    80004f32:	963e                	add	a2,a2,a5
    80004f34:	85be                	mv	a1,a5
    80004f36:	855e                	mv	a0,s7
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	4ea080e7          	jalr	1258(ra) # 80001422 <uvmalloc>
    80004f40:	8b2a                	mv	s6,a0
  ip = 0;
    80004f42:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f44:	12050c63          	beqz	a0,8000507c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f48:	75f9                	lui	a1,0xffffe
    80004f4a:	95aa                	add	a1,a1,a0
    80004f4c:	855e                	mv	a0,s7
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	6f2080e7          	jalr	1778(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f56:	7c7d                	lui	s8,0xfffff
    80004f58:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f5a:	e0043783          	ld	a5,-512(s0)
    80004f5e:	6388                	ld	a0,0(a5)
    80004f60:	c535                	beqz	a0,80004fcc <exec+0x216>
    80004f62:	e9040993          	addi	s3,s0,-368
    80004f66:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f6a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	ef8080e7          	jalr	-264(ra) # 80000e64 <strlen>
    80004f74:	2505                	addiw	a0,a0,1
    80004f76:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f7a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f7e:	13896363          	bltu	s2,s8,800050a4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f82:	e0043d83          	ld	s11,-512(s0)
    80004f86:	000dba03          	ld	s4,0(s11)
    80004f8a:	8552                	mv	a0,s4
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	ed8080e7          	jalr	-296(ra) # 80000e64 <strlen>
    80004f94:	0015069b          	addiw	a3,a0,1
    80004f98:	8652                	mv	a2,s4
    80004f9a:	85ca                	mv	a1,s2
    80004f9c:	855e                	mv	a0,s7
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	6d4080e7          	jalr	1748(ra) # 80001672 <copyout>
    80004fa6:	10054363          	bltz	a0,800050ac <exec+0x2f6>
    ustack[argc] = sp;
    80004faa:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fae:	0485                	addi	s1,s1,1
    80004fb0:	008d8793          	addi	a5,s11,8
    80004fb4:	e0f43023          	sd	a5,-512(s0)
    80004fb8:	008db503          	ld	a0,8(s11)
    80004fbc:	c911                	beqz	a0,80004fd0 <exec+0x21a>
    if(argc >= MAXARG)
    80004fbe:	09a1                	addi	s3,s3,8
    80004fc0:	fb3c96e3          	bne	s9,s3,80004f6c <exec+0x1b6>
  sz = sz1;
    80004fc4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc8:	4481                	li	s1,0
    80004fca:	a84d                	j	8000507c <exec+0x2c6>
  sp = sz;
    80004fcc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fce:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fd0:	00349793          	slli	a5,s1,0x3
    80004fd4:	f9040713          	addi	a4,s0,-112
    80004fd8:	97ba                	add	a5,a5,a4
    80004fda:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004fde:	00148693          	addi	a3,s1,1
    80004fe2:	068e                	slli	a3,a3,0x3
    80004fe4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fe8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fec:	01897663          	bgeu	s2,s8,80004ff8 <exec+0x242>
  sz = sz1;
    80004ff0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ff4:	4481                	li	s1,0
    80004ff6:	a059                	j	8000507c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ff8:	e9040613          	addi	a2,s0,-368
    80004ffc:	85ca                	mv	a1,s2
    80004ffe:	855e                	mv	a0,s7
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	672080e7          	jalr	1650(ra) # 80001672 <copyout>
    80005008:	0a054663          	bltz	a0,800050b4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000500c:	058ab783          	ld	a5,88(s5)
    80005010:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005014:	df843783          	ld	a5,-520(s0)
    80005018:	0007c703          	lbu	a4,0(a5)
    8000501c:	cf11                	beqz	a4,80005038 <exec+0x282>
    8000501e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005020:	02f00693          	li	a3,47
    80005024:	a039                	j	80005032 <exec+0x27c>
      last = s+1;
    80005026:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000502a:	0785                	addi	a5,a5,1
    8000502c:	fff7c703          	lbu	a4,-1(a5)
    80005030:	c701                	beqz	a4,80005038 <exec+0x282>
    if(*s == '/')
    80005032:	fed71ce3          	bne	a4,a3,8000502a <exec+0x274>
    80005036:	bfc5                	j	80005026 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005038:	4641                	li	a2,16
    8000503a:	df843583          	ld	a1,-520(s0)
    8000503e:	158a8513          	addi	a0,s5,344
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	df0080e7          	jalr	-528(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000504a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000504e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005052:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005056:	058ab783          	ld	a5,88(s5)
    8000505a:	e6843703          	ld	a4,-408(s0)
    8000505e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005060:	058ab783          	ld	a5,88(s5)
    80005064:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005068:	85ea                	mv	a1,s10
    8000506a:	ffffd097          	auipc	ra,0xffffd
    8000506e:	b96080e7          	jalr	-1130(ra) # 80001c00 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005072:	0004851b          	sext.w	a0,s1
    80005076:	bbe1                	j	80004e4e <exec+0x98>
    80005078:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000507c:	e0843583          	ld	a1,-504(s0)
    80005080:	855e                	mv	a0,s7
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	b7e080e7          	jalr	-1154(ra) # 80001c00 <proc_freepagetable>
  if(ip){
    8000508a:	da0498e3          	bnez	s1,80004e3a <exec+0x84>
  return -1;
    8000508e:	557d                	li	a0,-1
    80005090:	bb7d                	j	80004e4e <exec+0x98>
    80005092:	e1243423          	sd	s2,-504(s0)
    80005096:	b7dd                	j	8000507c <exec+0x2c6>
    80005098:	e1243423          	sd	s2,-504(s0)
    8000509c:	b7c5                	j	8000507c <exec+0x2c6>
    8000509e:	e1243423          	sd	s2,-504(s0)
    800050a2:	bfe9                	j	8000507c <exec+0x2c6>
  sz = sz1;
    800050a4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050a8:	4481                	li	s1,0
    800050aa:	bfc9                	j	8000507c <exec+0x2c6>
  sz = sz1;
    800050ac:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050b0:	4481                	li	s1,0
    800050b2:	b7e9                	j	8000507c <exec+0x2c6>
  sz = sz1;
    800050b4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050b8:	4481                	li	s1,0
    800050ba:	b7c9                	j	8000507c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050bc:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050c0:	2b05                	addiw	s6,s6,1
    800050c2:	0389899b          	addiw	s3,s3,56
    800050c6:	e8845783          	lhu	a5,-376(s0)
    800050ca:	e2fb5be3          	bge	s6,a5,80004f00 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050ce:	2981                	sext.w	s3,s3
    800050d0:	03800713          	li	a4,56
    800050d4:	86ce                	mv	a3,s3
    800050d6:	e1840613          	addi	a2,s0,-488
    800050da:	4581                	li	a1,0
    800050dc:	8526                	mv	a0,s1
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	a8e080e7          	jalr	-1394(ra) # 80003b6c <readi>
    800050e6:	03800793          	li	a5,56
    800050ea:	f8f517e3          	bne	a0,a5,80005078 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050ee:	e1842783          	lw	a5,-488(s0)
    800050f2:	4705                	li	a4,1
    800050f4:	fce796e3          	bne	a5,a4,800050c0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050f8:	e4043603          	ld	a2,-448(s0)
    800050fc:	e3843783          	ld	a5,-456(s0)
    80005100:	f8f669e3          	bltu	a2,a5,80005092 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005104:	e2843783          	ld	a5,-472(s0)
    80005108:	963e                	add	a2,a2,a5
    8000510a:	f8f667e3          	bltu	a2,a5,80005098 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000510e:	85ca                	mv	a1,s2
    80005110:	855e                	mv	a0,s7
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	310080e7          	jalr	784(ra) # 80001422 <uvmalloc>
    8000511a:	e0a43423          	sd	a0,-504(s0)
    8000511e:	d141                	beqz	a0,8000509e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005120:	e2843d03          	ld	s10,-472(s0)
    80005124:	df043783          	ld	a5,-528(s0)
    80005128:	00fd77b3          	and	a5,s10,a5
    8000512c:	fba1                	bnez	a5,8000507c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000512e:	e2042d83          	lw	s11,-480(s0)
    80005132:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005136:	f80c03e3          	beqz	s8,800050bc <exec+0x306>
    8000513a:	8a62                	mv	s4,s8
    8000513c:	4901                	li	s2,0
    8000513e:	b345                	j	80004ede <exec+0x128>

0000000080005140 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005140:	7179                	addi	sp,sp,-48
    80005142:	f406                	sd	ra,40(sp)
    80005144:	f022                	sd	s0,32(sp)
    80005146:	ec26                	sd	s1,24(sp)
    80005148:	e84a                	sd	s2,16(sp)
    8000514a:	1800                	addi	s0,sp,48
    8000514c:	892e                	mv	s2,a1
    8000514e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005150:	fdc40593          	addi	a1,s0,-36
    80005154:	ffffe097          	auipc	ra,0xffffe
    80005158:	b22080e7          	jalr	-1246(ra) # 80002c76 <argint>
    8000515c:	04054063          	bltz	a0,8000519c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005160:	fdc42703          	lw	a4,-36(s0)
    80005164:	47bd                	li	a5,15
    80005166:	02e7ed63          	bltu	a5,a4,800051a0 <argfd+0x60>
    8000516a:	ffffd097          	auipc	ra,0xffffd
    8000516e:	90a080e7          	jalr	-1782(ra) # 80001a74 <myproc>
    80005172:	fdc42703          	lw	a4,-36(s0)
    80005176:	01a70793          	addi	a5,a4,26
    8000517a:	078e                	slli	a5,a5,0x3
    8000517c:	953e                	add	a0,a0,a5
    8000517e:	611c                	ld	a5,0(a0)
    80005180:	c395                	beqz	a5,800051a4 <argfd+0x64>
    return -1;
  if(pfd)
    80005182:	00090463          	beqz	s2,8000518a <argfd+0x4a>
    *pfd = fd;
    80005186:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000518a:	4501                	li	a0,0
  if(pf)
    8000518c:	c091                	beqz	s1,80005190 <argfd+0x50>
    *pf = f;
    8000518e:	e09c                	sd	a5,0(s1)
}
    80005190:	70a2                	ld	ra,40(sp)
    80005192:	7402                	ld	s0,32(sp)
    80005194:	64e2                	ld	s1,24(sp)
    80005196:	6942                	ld	s2,16(sp)
    80005198:	6145                	addi	sp,sp,48
    8000519a:	8082                	ret
    return -1;
    8000519c:	557d                	li	a0,-1
    8000519e:	bfcd                	j	80005190 <argfd+0x50>
    return -1;
    800051a0:	557d                	li	a0,-1
    800051a2:	b7fd                	j	80005190 <argfd+0x50>
    800051a4:	557d                	li	a0,-1
    800051a6:	b7ed                	j	80005190 <argfd+0x50>

00000000800051a8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051a8:	1101                	addi	sp,sp,-32
    800051aa:	ec06                	sd	ra,24(sp)
    800051ac:	e822                	sd	s0,16(sp)
    800051ae:	e426                	sd	s1,8(sp)
    800051b0:	1000                	addi	s0,sp,32
    800051b2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051b4:	ffffd097          	auipc	ra,0xffffd
    800051b8:	8c0080e7          	jalr	-1856(ra) # 80001a74 <myproc>
    800051bc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051be:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800051c2:	4501                	li	a0,0
    800051c4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051c6:	6398                	ld	a4,0(a5)
    800051c8:	cb19                	beqz	a4,800051de <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051ca:	2505                	addiw	a0,a0,1
    800051cc:	07a1                	addi	a5,a5,8
    800051ce:	fed51ce3          	bne	a0,a3,800051c6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051d2:	557d                	li	a0,-1
}
    800051d4:	60e2                	ld	ra,24(sp)
    800051d6:	6442                	ld	s0,16(sp)
    800051d8:	64a2                	ld	s1,8(sp)
    800051da:	6105                	addi	sp,sp,32
    800051dc:	8082                	ret
      p->ofile[fd] = f;
    800051de:	01a50793          	addi	a5,a0,26
    800051e2:	078e                	slli	a5,a5,0x3
    800051e4:	963e                	add	a2,a2,a5
    800051e6:	e204                	sd	s1,0(a2)
      return fd;
    800051e8:	b7f5                	j	800051d4 <fdalloc+0x2c>

00000000800051ea <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051ea:	715d                	addi	sp,sp,-80
    800051ec:	e486                	sd	ra,72(sp)
    800051ee:	e0a2                	sd	s0,64(sp)
    800051f0:	fc26                	sd	s1,56(sp)
    800051f2:	f84a                	sd	s2,48(sp)
    800051f4:	f44e                	sd	s3,40(sp)
    800051f6:	f052                	sd	s4,32(sp)
    800051f8:	ec56                	sd	s5,24(sp)
    800051fa:	0880                	addi	s0,sp,80
    800051fc:	89ae                	mv	s3,a1
    800051fe:	8ab2                	mv	s5,a2
    80005200:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005202:	fb040593          	addi	a1,s0,-80
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	e86080e7          	jalr	-378(ra) # 8000408c <nameiparent>
    8000520e:	892a                	mv	s2,a0
    80005210:	12050f63          	beqz	a0,8000534e <create+0x164>
    return 0;

  ilock(dp);
    80005214:	ffffe097          	auipc	ra,0xffffe
    80005218:	6a4080e7          	jalr	1700(ra) # 800038b8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000521c:	4601                	li	a2,0
    8000521e:	fb040593          	addi	a1,s0,-80
    80005222:	854a                	mv	a0,s2
    80005224:	fffff097          	auipc	ra,0xfffff
    80005228:	b78080e7          	jalr	-1160(ra) # 80003d9c <dirlookup>
    8000522c:	84aa                	mv	s1,a0
    8000522e:	c921                	beqz	a0,8000527e <create+0x94>
    iunlockput(dp);
    80005230:	854a                	mv	a0,s2
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	8e8080e7          	jalr	-1816(ra) # 80003b1a <iunlockput>
    ilock(ip);
    8000523a:	8526                	mv	a0,s1
    8000523c:	ffffe097          	auipc	ra,0xffffe
    80005240:	67c080e7          	jalr	1660(ra) # 800038b8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005244:	2981                	sext.w	s3,s3
    80005246:	4789                	li	a5,2
    80005248:	02f99463          	bne	s3,a5,80005270 <create+0x86>
    8000524c:	0444d783          	lhu	a5,68(s1)
    80005250:	37f9                	addiw	a5,a5,-2
    80005252:	17c2                	slli	a5,a5,0x30
    80005254:	93c1                	srli	a5,a5,0x30
    80005256:	4705                	li	a4,1
    80005258:	00f76c63          	bltu	a4,a5,80005270 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000525c:	8526                	mv	a0,s1
    8000525e:	60a6                	ld	ra,72(sp)
    80005260:	6406                	ld	s0,64(sp)
    80005262:	74e2                	ld	s1,56(sp)
    80005264:	7942                	ld	s2,48(sp)
    80005266:	79a2                	ld	s3,40(sp)
    80005268:	7a02                	ld	s4,32(sp)
    8000526a:	6ae2                	ld	s5,24(sp)
    8000526c:	6161                	addi	sp,sp,80
    8000526e:	8082                	ret
    iunlockput(ip);
    80005270:	8526                	mv	a0,s1
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	8a8080e7          	jalr	-1880(ra) # 80003b1a <iunlockput>
    return 0;
    8000527a:	4481                	li	s1,0
    8000527c:	b7c5                	j	8000525c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000527e:	85ce                	mv	a1,s3
    80005280:	00092503          	lw	a0,0(s2)
    80005284:	ffffe097          	auipc	ra,0xffffe
    80005288:	49c080e7          	jalr	1180(ra) # 80003720 <ialloc>
    8000528c:	84aa                	mv	s1,a0
    8000528e:	c529                	beqz	a0,800052d8 <create+0xee>
  ilock(ip);
    80005290:	ffffe097          	auipc	ra,0xffffe
    80005294:	628080e7          	jalr	1576(ra) # 800038b8 <ilock>
  ip->major = major;
    80005298:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000529c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052a0:	4785                	li	a5,1
    800052a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052a6:	8526                	mv	a0,s1
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	546080e7          	jalr	1350(ra) # 800037ee <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052b0:	2981                	sext.w	s3,s3
    800052b2:	4785                	li	a5,1
    800052b4:	02f98a63          	beq	s3,a5,800052e8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052b8:	40d0                	lw	a2,4(s1)
    800052ba:	fb040593          	addi	a1,s0,-80
    800052be:	854a                	mv	a0,s2
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	cec080e7          	jalr	-788(ra) # 80003fac <dirlink>
    800052c8:	06054b63          	bltz	a0,8000533e <create+0x154>
  iunlockput(dp);
    800052cc:	854a                	mv	a0,s2
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	84c080e7          	jalr	-1972(ra) # 80003b1a <iunlockput>
  return ip;
    800052d6:	b759                	j	8000525c <create+0x72>
    panic("create: ialloc");
    800052d8:	00003517          	auipc	a0,0x3
    800052dc:	54850513          	addi	a0,a0,1352 # 80008820 <syscalls+0x300>
    800052e0:	ffffb097          	auipc	ra,0xffffb
    800052e4:	25e080e7          	jalr	606(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800052e8:	04a95783          	lhu	a5,74(s2)
    800052ec:	2785                	addiw	a5,a5,1
    800052ee:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052f2:	854a                	mv	a0,s2
    800052f4:	ffffe097          	auipc	ra,0xffffe
    800052f8:	4fa080e7          	jalr	1274(ra) # 800037ee <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052fc:	40d0                	lw	a2,4(s1)
    800052fe:	00003597          	auipc	a1,0x3
    80005302:	53258593          	addi	a1,a1,1330 # 80008830 <syscalls+0x310>
    80005306:	8526                	mv	a0,s1
    80005308:	fffff097          	auipc	ra,0xfffff
    8000530c:	ca4080e7          	jalr	-860(ra) # 80003fac <dirlink>
    80005310:	00054f63          	bltz	a0,8000532e <create+0x144>
    80005314:	00492603          	lw	a2,4(s2)
    80005318:	00003597          	auipc	a1,0x3
    8000531c:	52058593          	addi	a1,a1,1312 # 80008838 <syscalls+0x318>
    80005320:	8526                	mv	a0,s1
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	c8a080e7          	jalr	-886(ra) # 80003fac <dirlink>
    8000532a:	f80557e3          	bgez	a0,800052b8 <create+0xce>
      panic("create dots");
    8000532e:	00003517          	auipc	a0,0x3
    80005332:	51250513          	addi	a0,a0,1298 # 80008840 <syscalls+0x320>
    80005336:	ffffb097          	auipc	ra,0xffffb
    8000533a:	208080e7          	jalr	520(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000533e:	00003517          	auipc	a0,0x3
    80005342:	51250513          	addi	a0,a0,1298 # 80008850 <syscalls+0x330>
    80005346:	ffffb097          	auipc	ra,0xffffb
    8000534a:	1f8080e7          	jalr	504(ra) # 8000053e <panic>
    return 0;
    8000534e:	84aa                	mv	s1,a0
    80005350:	b731                	j	8000525c <create+0x72>

0000000080005352 <sys_dup>:
{
    80005352:	7179                	addi	sp,sp,-48
    80005354:	f406                	sd	ra,40(sp)
    80005356:	f022                	sd	s0,32(sp)
    80005358:	ec26                	sd	s1,24(sp)
    8000535a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000535c:	fd840613          	addi	a2,s0,-40
    80005360:	4581                	li	a1,0
    80005362:	4501                	li	a0,0
    80005364:	00000097          	auipc	ra,0x0
    80005368:	ddc080e7          	jalr	-548(ra) # 80005140 <argfd>
    return -1;
    8000536c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000536e:	02054363          	bltz	a0,80005394 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005372:	fd843503          	ld	a0,-40(s0)
    80005376:	00000097          	auipc	ra,0x0
    8000537a:	e32080e7          	jalr	-462(ra) # 800051a8 <fdalloc>
    8000537e:	84aa                	mv	s1,a0
    return -1;
    80005380:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005382:	00054963          	bltz	a0,80005394 <sys_dup+0x42>
  filedup(f);
    80005386:	fd843503          	ld	a0,-40(s0)
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	37a080e7          	jalr	890(ra) # 80004704 <filedup>
  return fd;
    80005392:	87a6                	mv	a5,s1
}
    80005394:	853e                	mv	a0,a5
    80005396:	70a2                	ld	ra,40(sp)
    80005398:	7402                	ld	s0,32(sp)
    8000539a:	64e2                	ld	s1,24(sp)
    8000539c:	6145                	addi	sp,sp,48
    8000539e:	8082                	ret

00000000800053a0 <sys_read>:
{
    800053a0:	7179                	addi	sp,sp,-48
    800053a2:	f406                	sd	ra,40(sp)
    800053a4:	f022                	sd	s0,32(sp)
    800053a6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a8:	fe840613          	addi	a2,s0,-24
    800053ac:	4581                	li	a1,0
    800053ae:	4501                	li	a0,0
    800053b0:	00000097          	auipc	ra,0x0
    800053b4:	d90080e7          	jalr	-624(ra) # 80005140 <argfd>
    return -1;
    800053b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ba:	04054163          	bltz	a0,800053fc <sys_read+0x5c>
    800053be:	fe440593          	addi	a1,s0,-28
    800053c2:	4509                	li	a0,2
    800053c4:	ffffe097          	auipc	ra,0xffffe
    800053c8:	8b2080e7          	jalr	-1870(ra) # 80002c76 <argint>
    return -1;
    800053cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ce:	02054763          	bltz	a0,800053fc <sys_read+0x5c>
    800053d2:	fd840593          	addi	a1,s0,-40
    800053d6:	4505                	li	a0,1
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	8c0080e7          	jalr	-1856(ra) # 80002c98 <argaddr>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e2:	00054d63          	bltz	a0,800053fc <sys_read+0x5c>
  return fileread(f, p, n);
    800053e6:	fe442603          	lw	a2,-28(s0)
    800053ea:	fd843583          	ld	a1,-40(s0)
    800053ee:	fe843503          	ld	a0,-24(s0)
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	49e080e7          	jalr	1182(ra) # 80004890 <fileread>
    800053fa:	87aa                	mv	a5,a0
}
    800053fc:	853e                	mv	a0,a5
    800053fe:	70a2                	ld	ra,40(sp)
    80005400:	7402                	ld	s0,32(sp)
    80005402:	6145                	addi	sp,sp,48
    80005404:	8082                	ret

0000000080005406 <sys_write>:
{
    80005406:	7179                	addi	sp,sp,-48
    80005408:	f406                	sd	ra,40(sp)
    8000540a:	f022                	sd	s0,32(sp)
    8000540c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000540e:	fe840613          	addi	a2,s0,-24
    80005412:	4581                	li	a1,0
    80005414:	4501                	li	a0,0
    80005416:	00000097          	auipc	ra,0x0
    8000541a:	d2a080e7          	jalr	-726(ra) # 80005140 <argfd>
    return -1;
    8000541e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005420:	04054163          	bltz	a0,80005462 <sys_write+0x5c>
    80005424:	fe440593          	addi	a1,s0,-28
    80005428:	4509                	li	a0,2
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	84c080e7          	jalr	-1972(ra) # 80002c76 <argint>
    return -1;
    80005432:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005434:	02054763          	bltz	a0,80005462 <sys_write+0x5c>
    80005438:	fd840593          	addi	a1,s0,-40
    8000543c:	4505                	li	a0,1
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	85a080e7          	jalr	-1958(ra) # 80002c98 <argaddr>
    return -1;
    80005446:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005448:	00054d63          	bltz	a0,80005462 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000544c:	fe442603          	lw	a2,-28(s0)
    80005450:	fd843583          	ld	a1,-40(s0)
    80005454:	fe843503          	ld	a0,-24(s0)
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	4fa080e7          	jalr	1274(ra) # 80004952 <filewrite>
    80005460:	87aa                	mv	a5,a0
}
    80005462:	853e                	mv	a0,a5
    80005464:	70a2                	ld	ra,40(sp)
    80005466:	7402                	ld	s0,32(sp)
    80005468:	6145                	addi	sp,sp,48
    8000546a:	8082                	ret

000000008000546c <sys_close>:
{
    8000546c:	1101                	addi	sp,sp,-32
    8000546e:	ec06                	sd	ra,24(sp)
    80005470:	e822                	sd	s0,16(sp)
    80005472:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005474:	fe040613          	addi	a2,s0,-32
    80005478:	fec40593          	addi	a1,s0,-20
    8000547c:	4501                	li	a0,0
    8000547e:	00000097          	auipc	ra,0x0
    80005482:	cc2080e7          	jalr	-830(ra) # 80005140 <argfd>
    return -1;
    80005486:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005488:	02054463          	bltz	a0,800054b0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000548c:	ffffc097          	auipc	ra,0xffffc
    80005490:	5e8080e7          	jalr	1512(ra) # 80001a74 <myproc>
    80005494:	fec42783          	lw	a5,-20(s0)
    80005498:	07e9                	addi	a5,a5,26
    8000549a:	078e                	slli	a5,a5,0x3
    8000549c:	97aa                	add	a5,a5,a0
    8000549e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054a2:	fe043503          	ld	a0,-32(s0)
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	2b0080e7          	jalr	688(ra) # 80004756 <fileclose>
  return 0;
    800054ae:	4781                	li	a5,0
}
    800054b0:	853e                	mv	a0,a5
    800054b2:	60e2                	ld	ra,24(sp)
    800054b4:	6442                	ld	s0,16(sp)
    800054b6:	6105                	addi	sp,sp,32
    800054b8:	8082                	ret

00000000800054ba <sys_fstat>:
{
    800054ba:	1101                	addi	sp,sp,-32
    800054bc:	ec06                	sd	ra,24(sp)
    800054be:	e822                	sd	s0,16(sp)
    800054c0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054c2:	fe840613          	addi	a2,s0,-24
    800054c6:	4581                	li	a1,0
    800054c8:	4501                	li	a0,0
    800054ca:	00000097          	auipc	ra,0x0
    800054ce:	c76080e7          	jalr	-906(ra) # 80005140 <argfd>
    return -1;
    800054d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054d4:	02054563          	bltz	a0,800054fe <sys_fstat+0x44>
    800054d8:	fe040593          	addi	a1,s0,-32
    800054dc:	4505                	li	a0,1
    800054de:	ffffd097          	auipc	ra,0xffffd
    800054e2:	7ba080e7          	jalr	1978(ra) # 80002c98 <argaddr>
    return -1;
    800054e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054e8:	00054b63          	bltz	a0,800054fe <sys_fstat+0x44>
  return filestat(f, st);
    800054ec:	fe043583          	ld	a1,-32(s0)
    800054f0:	fe843503          	ld	a0,-24(s0)
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	32a080e7          	jalr	810(ra) # 8000481e <filestat>
    800054fc:	87aa                	mv	a5,a0
}
    800054fe:	853e                	mv	a0,a5
    80005500:	60e2                	ld	ra,24(sp)
    80005502:	6442                	ld	s0,16(sp)
    80005504:	6105                	addi	sp,sp,32
    80005506:	8082                	ret

0000000080005508 <sys_link>:
{
    80005508:	7169                	addi	sp,sp,-304
    8000550a:	f606                	sd	ra,296(sp)
    8000550c:	f222                	sd	s0,288(sp)
    8000550e:	ee26                	sd	s1,280(sp)
    80005510:	ea4a                	sd	s2,272(sp)
    80005512:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005514:	08000613          	li	a2,128
    80005518:	ed040593          	addi	a1,s0,-304
    8000551c:	4501                	li	a0,0
    8000551e:	ffffd097          	auipc	ra,0xffffd
    80005522:	79c080e7          	jalr	1948(ra) # 80002cba <argstr>
    return -1;
    80005526:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005528:	10054e63          	bltz	a0,80005644 <sys_link+0x13c>
    8000552c:	08000613          	li	a2,128
    80005530:	f5040593          	addi	a1,s0,-176
    80005534:	4505                	li	a0,1
    80005536:	ffffd097          	auipc	ra,0xffffd
    8000553a:	784080e7          	jalr	1924(ra) # 80002cba <argstr>
    return -1;
    8000553e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005540:	10054263          	bltz	a0,80005644 <sys_link+0x13c>
  begin_op();
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	d46080e7          	jalr	-698(ra) # 8000428a <begin_op>
  if((ip = namei(old)) == 0){
    8000554c:	ed040513          	addi	a0,s0,-304
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	b1e080e7          	jalr	-1250(ra) # 8000406e <namei>
    80005558:	84aa                	mv	s1,a0
    8000555a:	c551                	beqz	a0,800055e6 <sys_link+0xde>
  ilock(ip);
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	35c080e7          	jalr	860(ra) # 800038b8 <ilock>
  if(ip->type == T_DIR){
    80005564:	04449703          	lh	a4,68(s1)
    80005568:	4785                	li	a5,1
    8000556a:	08f70463          	beq	a4,a5,800055f2 <sys_link+0xea>
  ip->nlink++;
    8000556e:	04a4d783          	lhu	a5,74(s1)
    80005572:	2785                	addiw	a5,a5,1
    80005574:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	274080e7          	jalr	628(ra) # 800037ee <iupdate>
  iunlock(ip);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	3f6080e7          	jalr	1014(ra) # 8000397a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000558c:	fd040593          	addi	a1,s0,-48
    80005590:	f5040513          	addi	a0,s0,-176
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	af8080e7          	jalr	-1288(ra) # 8000408c <nameiparent>
    8000559c:	892a                	mv	s2,a0
    8000559e:	c935                	beqz	a0,80005612 <sys_link+0x10a>
  ilock(dp);
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	318080e7          	jalr	792(ra) # 800038b8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055a8:	00092703          	lw	a4,0(s2)
    800055ac:	409c                	lw	a5,0(s1)
    800055ae:	04f71d63          	bne	a4,a5,80005608 <sys_link+0x100>
    800055b2:	40d0                	lw	a2,4(s1)
    800055b4:	fd040593          	addi	a1,s0,-48
    800055b8:	854a                	mv	a0,s2
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	9f2080e7          	jalr	-1550(ra) # 80003fac <dirlink>
    800055c2:	04054363          	bltz	a0,80005608 <sys_link+0x100>
  iunlockput(dp);
    800055c6:	854a                	mv	a0,s2
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	552080e7          	jalr	1362(ra) # 80003b1a <iunlockput>
  iput(ip);
    800055d0:	8526                	mv	a0,s1
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	4a0080e7          	jalr	1184(ra) # 80003a72 <iput>
  end_op();
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	d30080e7          	jalr	-720(ra) # 8000430a <end_op>
  return 0;
    800055e2:	4781                	li	a5,0
    800055e4:	a085                	j	80005644 <sys_link+0x13c>
    end_op();
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	d24080e7          	jalr	-732(ra) # 8000430a <end_op>
    return -1;
    800055ee:	57fd                	li	a5,-1
    800055f0:	a891                	j	80005644 <sys_link+0x13c>
    iunlockput(ip);
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	526080e7          	jalr	1318(ra) # 80003b1a <iunlockput>
    end_op();
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	d0e080e7          	jalr	-754(ra) # 8000430a <end_op>
    return -1;
    80005604:	57fd                	li	a5,-1
    80005606:	a83d                	j	80005644 <sys_link+0x13c>
    iunlockput(dp);
    80005608:	854a                	mv	a0,s2
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	510080e7          	jalr	1296(ra) # 80003b1a <iunlockput>
  ilock(ip);
    80005612:	8526                	mv	a0,s1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	2a4080e7          	jalr	676(ra) # 800038b8 <ilock>
  ip->nlink--;
    8000561c:	04a4d783          	lhu	a5,74(s1)
    80005620:	37fd                	addiw	a5,a5,-1
    80005622:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005626:	8526                	mv	a0,s1
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	1c6080e7          	jalr	454(ra) # 800037ee <iupdate>
  iunlockput(ip);
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	4e8080e7          	jalr	1256(ra) # 80003b1a <iunlockput>
  end_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	cd0080e7          	jalr	-816(ra) # 8000430a <end_op>
  return -1;
    80005642:	57fd                	li	a5,-1
}
    80005644:	853e                	mv	a0,a5
    80005646:	70b2                	ld	ra,296(sp)
    80005648:	7412                	ld	s0,288(sp)
    8000564a:	64f2                	ld	s1,280(sp)
    8000564c:	6952                	ld	s2,272(sp)
    8000564e:	6155                	addi	sp,sp,304
    80005650:	8082                	ret

0000000080005652 <sys_unlink>:
{
    80005652:	7151                	addi	sp,sp,-240
    80005654:	f586                	sd	ra,232(sp)
    80005656:	f1a2                	sd	s0,224(sp)
    80005658:	eda6                	sd	s1,216(sp)
    8000565a:	e9ca                	sd	s2,208(sp)
    8000565c:	e5ce                	sd	s3,200(sp)
    8000565e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005660:	08000613          	li	a2,128
    80005664:	f3040593          	addi	a1,s0,-208
    80005668:	4501                	li	a0,0
    8000566a:	ffffd097          	auipc	ra,0xffffd
    8000566e:	650080e7          	jalr	1616(ra) # 80002cba <argstr>
    80005672:	18054163          	bltz	a0,800057f4 <sys_unlink+0x1a2>
  begin_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	c14080e7          	jalr	-1004(ra) # 8000428a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000567e:	fb040593          	addi	a1,s0,-80
    80005682:	f3040513          	addi	a0,s0,-208
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	a06080e7          	jalr	-1530(ra) # 8000408c <nameiparent>
    8000568e:	84aa                	mv	s1,a0
    80005690:	c979                	beqz	a0,80005766 <sys_unlink+0x114>
  ilock(dp);
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	226080e7          	jalr	550(ra) # 800038b8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000569a:	00003597          	auipc	a1,0x3
    8000569e:	19658593          	addi	a1,a1,406 # 80008830 <syscalls+0x310>
    800056a2:	fb040513          	addi	a0,s0,-80
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	6dc080e7          	jalr	1756(ra) # 80003d82 <namecmp>
    800056ae:	14050a63          	beqz	a0,80005802 <sys_unlink+0x1b0>
    800056b2:	00003597          	auipc	a1,0x3
    800056b6:	18658593          	addi	a1,a1,390 # 80008838 <syscalls+0x318>
    800056ba:	fb040513          	addi	a0,s0,-80
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	6c4080e7          	jalr	1732(ra) # 80003d82 <namecmp>
    800056c6:	12050e63          	beqz	a0,80005802 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056ca:	f2c40613          	addi	a2,s0,-212
    800056ce:	fb040593          	addi	a1,s0,-80
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	6c8080e7          	jalr	1736(ra) # 80003d9c <dirlookup>
    800056dc:	892a                	mv	s2,a0
    800056de:	12050263          	beqz	a0,80005802 <sys_unlink+0x1b0>
  ilock(ip);
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	1d6080e7          	jalr	470(ra) # 800038b8 <ilock>
  if(ip->nlink < 1)
    800056ea:	04a91783          	lh	a5,74(s2)
    800056ee:	08f05263          	blez	a5,80005772 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056f2:	04491703          	lh	a4,68(s2)
    800056f6:	4785                	li	a5,1
    800056f8:	08f70563          	beq	a4,a5,80005782 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056fc:	4641                	li	a2,16
    800056fe:	4581                	li	a1,0
    80005700:	fc040513          	addi	a0,s0,-64
    80005704:	ffffb097          	auipc	ra,0xffffb
    80005708:	5dc080e7          	jalr	1500(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000570c:	4741                	li	a4,16
    8000570e:	f2c42683          	lw	a3,-212(s0)
    80005712:	fc040613          	addi	a2,s0,-64
    80005716:	4581                	li	a1,0
    80005718:	8526                	mv	a0,s1
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	54a080e7          	jalr	1354(ra) # 80003c64 <writei>
    80005722:	47c1                	li	a5,16
    80005724:	0af51563          	bne	a0,a5,800057ce <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005728:	04491703          	lh	a4,68(s2)
    8000572c:	4785                	li	a5,1
    8000572e:	0af70863          	beq	a4,a5,800057de <sys_unlink+0x18c>
  iunlockput(dp);
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	3e6080e7          	jalr	998(ra) # 80003b1a <iunlockput>
  ip->nlink--;
    8000573c:	04a95783          	lhu	a5,74(s2)
    80005740:	37fd                	addiw	a5,a5,-1
    80005742:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005746:	854a                	mv	a0,s2
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	0a6080e7          	jalr	166(ra) # 800037ee <iupdate>
  iunlockput(ip);
    80005750:	854a                	mv	a0,s2
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	3c8080e7          	jalr	968(ra) # 80003b1a <iunlockput>
  end_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	bb0080e7          	jalr	-1104(ra) # 8000430a <end_op>
  return 0;
    80005762:	4501                	li	a0,0
    80005764:	a84d                	j	80005816 <sys_unlink+0x1c4>
    end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	ba4080e7          	jalr	-1116(ra) # 8000430a <end_op>
    return -1;
    8000576e:	557d                	li	a0,-1
    80005770:	a05d                	j	80005816 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005772:	00003517          	auipc	a0,0x3
    80005776:	0ee50513          	addi	a0,a0,238 # 80008860 <syscalls+0x340>
    8000577a:	ffffb097          	auipc	ra,0xffffb
    8000577e:	dc4080e7          	jalr	-572(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005782:	04c92703          	lw	a4,76(s2)
    80005786:	02000793          	li	a5,32
    8000578a:	f6e7f9e3          	bgeu	a5,a4,800056fc <sys_unlink+0xaa>
    8000578e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005792:	4741                	li	a4,16
    80005794:	86ce                	mv	a3,s3
    80005796:	f1840613          	addi	a2,s0,-232
    8000579a:	4581                	li	a1,0
    8000579c:	854a                	mv	a0,s2
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	3ce080e7          	jalr	974(ra) # 80003b6c <readi>
    800057a6:	47c1                	li	a5,16
    800057a8:	00f51b63          	bne	a0,a5,800057be <sys_unlink+0x16c>
    if(de.inum != 0)
    800057ac:	f1845783          	lhu	a5,-232(s0)
    800057b0:	e7a1                	bnez	a5,800057f8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057b2:	29c1                	addiw	s3,s3,16
    800057b4:	04c92783          	lw	a5,76(s2)
    800057b8:	fcf9ede3          	bltu	s3,a5,80005792 <sys_unlink+0x140>
    800057bc:	b781                	j	800056fc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057be:	00003517          	auipc	a0,0x3
    800057c2:	0ba50513          	addi	a0,a0,186 # 80008878 <syscalls+0x358>
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	d78080e7          	jalr	-648(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057ce:	00003517          	auipc	a0,0x3
    800057d2:	0c250513          	addi	a0,a0,194 # 80008890 <syscalls+0x370>
    800057d6:	ffffb097          	auipc	ra,0xffffb
    800057da:	d68080e7          	jalr	-664(ra) # 8000053e <panic>
    dp->nlink--;
    800057de:	04a4d783          	lhu	a5,74(s1)
    800057e2:	37fd                	addiw	a5,a5,-1
    800057e4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057e8:	8526                	mv	a0,s1
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	004080e7          	jalr	4(ra) # 800037ee <iupdate>
    800057f2:	b781                	j	80005732 <sys_unlink+0xe0>
    return -1;
    800057f4:	557d                	li	a0,-1
    800057f6:	a005                	j	80005816 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057f8:	854a                	mv	a0,s2
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	320080e7          	jalr	800(ra) # 80003b1a <iunlockput>
  iunlockput(dp);
    80005802:	8526                	mv	a0,s1
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	316080e7          	jalr	790(ra) # 80003b1a <iunlockput>
  end_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	afe080e7          	jalr	-1282(ra) # 8000430a <end_op>
  return -1;
    80005814:	557d                	li	a0,-1
}
    80005816:	70ae                	ld	ra,232(sp)
    80005818:	740e                	ld	s0,224(sp)
    8000581a:	64ee                	ld	s1,216(sp)
    8000581c:	694e                	ld	s2,208(sp)
    8000581e:	69ae                	ld	s3,200(sp)
    80005820:	616d                	addi	sp,sp,240
    80005822:	8082                	ret

0000000080005824 <sys_open>:

uint64
sys_open(void)
{
    80005824:	7131                	addi	sp,sp,-192
    80005826:	fd06                	sd	ra,184(sp)
    80005828:	f922                	sd	s0,176(sp)
    8000582a:	f526                	sd	s1,168(sp)
    8000582c:	f14a                	sd	s2,160(sp)
    8000582e:	ed4e                	sd	s3,152(sp)
    80005830:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005832:	08000613          	li	a2,128
    80005836:	f5040593          	addi	a1,s0,-176
    8000583a:	4501                	li	a0,0
    8000583c:	ffffd097          	auipc	ra,0xffffd
    80005840:	47e080e7          	jalr	1150(ra) # 80002cba <argstr>
    return -1;
    80005844:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005846:	0c054163          	bltz	a0,80005908 <sys_open+0xe4>
    8000584a:	f4c40593          	addi	a1,s0,-180
    8000584e:	4505                	li	a0,1
    80005850:	ffffd097          	auipc	ra,0xffffd
    80005854:	426080e7          	jalr	1062(ra) # 80002c76 <argint>
    80005858:	0a054863          	bltz	a0,80005908 <sys_open+0xe4>

  begin_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	a2e080e7          	jalr	-1490(ra) # 8000428a <begin_op>

  if(omode & O_CREATE){
    80005864:	f4c42783          	lw	a5,-180(s0)
    80005868:	2007f793          	andi	a5,a5,512
    8000586c:	cbdd                	beqz	a5,80005922 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000586e:	4681                	li	a3,0
    80005870:	4601                	li	a2,0
    80005872:	4589                	li	a1,2
    80005874:	f5040513          	addi	a0,s0,-176
    80005878:	00000097          	auipc	ra,0x0
    8000587c:	972080e7          	jalr	-1678(ra) # 800051ea <create>
    80005880:	892a                	mv	s2,a0
    if(ip == 0){
    80005882:	c959                	beqz	a0,80005918 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005884:	04491703          	lh	a4,68(s2)
    80005888:	478d                	li	a5,3
    8000588a:	00f71763          	bne	a4,a5,80005898 <sys_open+0x74>
    8000588e:	04695703          	lhu	a4,70(s2)
    80005892:	47a5                	li	a5,9
    80005894:	0ce7ec63          	bltu	a5,a4,8000596c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	e02080e7          	jalr	-510(ra) # 8000469a <filealloc>
    800058a0:	89aa                	mv	s3,a0
    800058a2:	10050263          	beqz	a0,800059a6 <sys_open+0x182>
    800058a6:	00000097          	auipc	ra,0x0
    800058aa:	902080e7          	jalr	-1790(ra) # 800051a8 <fdalloc>
    800058ae:	84aa                	mv	s1,a0
    800058b0:	0e054663          	bltz	a0,8000599c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058b4:	04491703          	lh	a4,68(s2)
    800058b8:	478d                	li	a5,3
    800058ba:	0cf70463          	beq	a4,a5,80005982 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058be:	4789                	li	a5,2
    800058c0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058c4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058c8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058cc:	f4c42783          	lw	a5,-180(s0)
    800058d0:	0017c713          	xori	a4,a5,1
    800058d4:	8b05                	andi	a4,a4,1
    800058d6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058da:	0037f713          	andi	a4,a5,3
    800058de:	00e03733          	snez	a4,a4
    800058e2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058e6:	4007f793          	andi	a5,a5,1024
    800058ea:	c791                	beqz	a5,800058f6 <sys_open+0xd2>
    800058ec:	04491703          	lh	a4,68(s2)
    800058f0:	4789                	li	a5,2
    800058f2:	08f70f63          	beq	a4,a5,80005990 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058f6:	854a                	mv	a0,s2
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	082080e7          	jalr	130(ra) # 8000397a <iunlock>
  end_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	a0a080e7          	jalr	-1526(ra) # 8000430a <end_op>

  return fd;
}
    80005908:	8526                	mv	a0,s1
    8000590a:	70ea                	ld	ra,184(sp)
    8000590c:	744a                	ld	s0,176(sp)
    8000590e:	74aa                	ld	s1,168(sp)
    80005910:	790a                	ld	s2,160(sp)
    80005912:	69ea                	ld	s3,152(sp)
    80005914:	6129                	addi	sp,sp,192
    80005916:	8082                	ret
      end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	9f2080e7          	jalr	-1550(ra) # 8000430a <end_op>
      return -1;
    80005920:	b7e5                	j	80005908 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005922:	f5040513          	addi	a0,s0,-176
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	748080e7          	jalr	1864(ra) # 8000406e <namei>
    8000592e:	892a                	mv	s2,a0
    80005930:	c905                	beqz	a0,80005960 <sys_open+0x13c>
    ilock(ip);
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	f86080e7          	jalr	-122(ra) # 800038b8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000593a:	04491703          	lh	a4,68(s2)
    8000593e:	4785                	li	a5,1
    80005940:	f4f712e3          	bne	a4,a5,80005884 <sys_open+0x60>
    80005944:	f4c42783          	lw	a5,-180(s0)
    80005948:	dba1                	beqz	a5,80005898 <sys_open+0x74>
      iunlockput(ip);
    8000594a:	854a                	mv	a0,s2
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	1ce080e7          	jalr	462(ra) # 80003b1a <iunlockput>
      end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	9b6080e7          	jalr	-1610(ra) # 8000430a <end_op>
      return -1;
    8000595c:	54fd                	li	s1,-1
    8000595e:	b76d                	j	80005908 <sys_open+0xe4>
      end_op();
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	9aa080e7          	jalr	-1622(ra) # 8000430a <end_op>
      return -1;
    80005968:	54fd                	li	s1,-1
    8000596a:	bf79                	j	80005908 <sys_open+0xe4>
    iunlockput(ip);
    8000596c:	854a                	mv	a0,s2
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	1ac080e7          	jalr	428(ra) # 80003b1a <iunlockput>
    end_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	994080e7          	jalr	-1644(ra) # 8000430a <end_op>
    return -1;
    8000597e:	54fd                	li	s1,-1
    80005980:	b761                	j	80005908 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005982:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005986:	04691783          	lh	a5,70(s2)
    8000598a:	02f99223          	sh	a5,36(s3)
    8000598e:	bf2d                	j	800058c8 <sys_open+0xa4>
    itrunc(ip);
    80005990:	854a                	mv	a0,s2
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	034080e7          	jalr	52(ra) # 800039c6 <itrunc>
    8000599a:	bfb1                	j	800058f6 <sys_open+0xd2>
      fileclose(f);
    8000599c:	854e                	mv	a0,s3
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	db8080e7          	jalr	-584(ra) # 80004756 <fileclose>
    iunlockput(ip);
    800059a6:	854a                	mv	a0,s2
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	172080e7          	jalr	370(ra) # 80003b1a <iunlockput>
    end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	95a080e7          	jalr	-1702(ra) # 8000430a <end_op>
    return -1;
    800059b8:	54fd                	li	s1,-1
    800059ba:	b7b9                	j	80005908 <sys_open+0xe4>

00000000800059bc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059bc:	7175                	addi	sp,sp,-144
    800059be:	e506                	sd	ra,136(sp)
    800059c0:	e122                	sd	s0,128(sp)
    800059c2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	8c6080e7          	jalr	-1850(ra) # 8000428a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059cc:	08000613          	li	a2,128
    800059d0:	f7040593          	addi	a1,s0,-144
    800059d4:	4501                	li	a0,0
    800059d6:	ffffd097          	auipc	ra,0xffffd
    800059da:	2e4080e7          	jalr	740(ra) # 80002cba <argstr>
    800059de:	02054963          	bltz	a0,80005a10 <sys_mkdir+0x54>
    800059e2:	4681                	li	a3,0
    800059e4:	4601                	li	a2,0
    800059e6:	4585                	li	a1,1
    800059e8:	f7040513          	addi	a0,s0,-144
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	7fe080e7          	jalr	2046(ra) # 800051ea <create>
    800059f4:	cd11                	beqz	a0,80005a10 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	124080e7          	jalr	292(ra) # 80003b1a <iunlockput>
  end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	90c080e7          	jalr	-1780(ra) # 8000430a <end_op>
  return 0;
    80005a06:	4501                	li	a0,0
}
    80005a08:	60aa                	ld	ra,136(sp)
    80005a0a:	640a                	ld	s0,128(sp)
    80005a0c:	6149                	addi	sp,sp,144
    80005a0e:	8082                	ret
    end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	8fa080e7          	jalr	-1798(ra) # 8000430a <end_op>
    return -1;
    80005a18:	557d                	li	a0,-1
    80005a1a:	b7fd                	j	80005a08 <sys_mkdir+0x4c>

0000000080005a1c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a1c:	7135                	addi	sp,sp,-160
    80005a1e:	ed06                	sd	ra,152(sp)
    80005a20:	e922                	sd	s0,144(sp)
    80005a22:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	866080e7          	jalr	-1946(ra) # 8000428a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a2c:	08000613          	li	a2,128
    80005a30:	f7040593          	addi	a1,s0,-144
    80005a34:	4501                	li	a0,0
    80005a36:	ffffd097          	auipc	ra,0xffffd
    80005a3a:	284080e7          	jalr	644(ra) # 80002cba <argstr>
    80005a3e:	04054a63          	bltz	a0,80005a92 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a42:	f6c40593          	addi	a1,s0,-148
    80005a46:	4505                	li	a0,1
    80005a48:	ffffd097          	auipc	ra,0xffffd
    80005a4c:	22e080e7          	jalr	558(ra) # 80002c76 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a50:	04054163          	bltz	a0,80005a92 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a54:	f6840593          	addi	a1,s0,-152
    80005a58:	4509                	li	a0,2
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	21c080e7          	jalr	540(ra) # 80002c76 <argint>
     argint(1, &major) < 0 ||
    80005a62:	02054863          	bltz	a0,80005a92 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a66:	f6841683          	lh	a3,-152(s0)
    80005a6a:	f6c41603          	lh	a2,-148(s0)
    80005a6e:	458d                	li	a1,3
    80005a70:	f7040513          	addi	a0,s0,-144
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	776080e7          	jalr	1910(ra) # 800051ea <create>
     argint(2, &minor) < 0 ||
    80005a7c:	c919                	beqz	a0,80005a92 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	09c080e7          	jalr	156(ra) # 80003b1a <iunlockput>
  end_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	884080e7          	jalr	-1916(ra) # 8000430a <end_op>
  return 0;
    80005a8e:	4501                	li	a0,0
    80005a90:	a031                	j	80005a9c <sys_mknod+0x80>
    end_op();
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	878080e7          	jalr	-1928(ra) # 8000430a <end_op>
    return -1;
    80005a9a:	557d                	li	a0,-1
}
    80005a9c:	60ea                	ld	ra,152(sp)
    80005a9e:	644a                	ld	s0,144(sp)
    80005aa0:	610d                	addi	sp,sp,160
    80005aa2:	8082                	ret

0000000080005aa4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005aa4:	7135                	addi	sp,sp,-160
    80005aa6:	ed06                	sd	ra,152(sp)
    80005aa8:	e922                	sd	s0,144(sp)
    80005aaa:	e526                	sd	s1,136(sp)
    80005aac:	e14a                	sd	s2,128(sp)
    80005aae:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ab0:	ffffc097          	auipc	ra,0xffffc
    80005ab4:	fc4080e7          	jalr	-60(ra) # 80001a74 <myproc>
    80005ab8:	892a                	mv	s2,a0
  
  begin_op();
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	7d0080e7          	jalr	2000(ra) # 8000428a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ac2:	08000613          	li	a2,128
    80005ac6:	f6040593          	addi	a1,s0,-160
    80005aca:	4501                	li	a0,0
    80005acc:	ffffd097          	auipc	ra,0xffffd
    80005ad0:	1ee080e7          	jalr	494(ra) # 80002cba <argstr>
    80005ad4:	04054b63          	bltz	a0,80005b2a <sys_chdir+0x86>
    80005ad8:	f6040513          	addi	a0,s0,-160
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	592080e7          	jalr	1426(ra) # 8000406e <namei>
    80005ae4:	84aa                	mv	s1,a0
    80005ae6:	c131                	beqz	a0,80005b2a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	dd0080e7          	jalr	-560(ra) # 800038b8 <ilock>
  if(ip->type != T_DIR){
    80005af0:	04449703          	lh	a4,68(s1)
    80005af4:	4785                	li	a5,1
    80005af6:	04f71063          	bne	a4,a5,80005b36 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005afa:	8526                	mv	a0,s1
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	e7e080e7          	jalr	-386(ra) # 8000397a <iunlock>
  iput(p->cwd);
    80005b04:	15093503          	ld	a0,336(s2)
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	f6a080e7          	jalr	-150(ra) # 80003a72 <iput>
  end_op();
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	7fa080e7          	jalr	2042(ra) # 8000430a <end_op>
  p->cwd = ip;
    80005b18:	14993823          	sd	s1,336(s2)
  return 0;
    80005b1c:	4501                	li	a0,0
}
    80005b1e:	60ea                	ld	ra,152(sp)
    80005b20:	644a                	ld	s0,144(sp)
    80005b22:	64aa                	ld	s1,136(sp)
    80005b24:	690a                	ld	s2,128(sp)
    80005b26:	610d                	addi	sp,sp,160
    80005b28:	8082                	ret
    end_op();
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	7e0080e7          	jalr	2016(ra) # 8000430a <end_op>
    return -1;
    80005b32:	557d                	li	a0,-1
    80005b34:	b7ed                	j	80005b1e <sys_chdir+0x7a>
    iunlockput(ip);
    80005b36:	8526                	mv	a0,s1
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	fe2080e7          	jalr	-30(ra) # 80003b1a <iunlockput>
    end_op();
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	7ca080e7          	jalr	1994(ra) # 8000430a <end_op>
    return -1;
    80005b48:	557d                	li	a0,-1
    80005b4a:	bfd1                	j	80005b1e <sys_chdir+0x7a>

0000000080005b4c <sys_exec>:

uint64
sys_exec(void)
{
    80005b4c:	7145                	addi	sp,sp,-464
    80005b4e:	e786                	sd	ra,456(sp)
    80005b50:	e3a2                	sd	s0,448(sp)
    80005b52:	ff26                	sd	s1,440(sp)
    80005b54:	fb4a                	sd	s2,432(sp)
    80005b56:	f74e                	sd	s3,424(sp)
    80005b58:	f352                	sd	s4,416(sp)
    80005b5a:	ef56                	sd	s5,408(sp)
    80005b5c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b5e:	08000613          	li	a2,128
    80005b62:	f4040593          	addi	a1,s0,-192
    80005b66:	4501                	li	a0,0
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	152080e7          	jalr	338(ra) # 80002cba <argstr>
    return -1;
    80005b70:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b72:	0c054a63          	bltz	a0,80005c46 <sys_exec+0xfa>
    80005b76:	e3840593          	addi	a1,s0,-456
    80005b7a:	4505                	li	a0,1
    80005b7c:	ffffd097          	auipc	ra,0xffffd
    80005b80:	11c080e7          	jalr	284(ra) # 80002c98 <argaddr>
    80005b84:	0c054163          	bltz	a0,80005c46 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b88:	10000613          	li	a2,256
    80005b8c:	4581                	li	a1,0
    80005b8e:	e4040513          	addi	a0,s0,-448
    80005b92:	ffffb097          	auipc	ra,0xffffb
    80005b96:	14e080e7          	jalr	334(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b9a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b9e:	89a6                	mv	s3,s1
    80005ba0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ba2:	02000a13          	li	s4,32
    80005ba6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005baa:	00391513          	slli	a0,s2,0x3
    80005bae:	e3040593          	addi	a1,s0,-464
    80005bb2:	e3843783          	ld	a5,-456(s0)
    80005bb6:	953e                	add	a0,a0,a5
    80005bb8:	ffffd097          	auipc	ra,0xffffd
    80005bbc:	024080e7          	jalr	36(ra) # 80002bdc <fetchaddr>
    80005bc0:	02054a63          	bltz	a0,80005bf4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bc4:	e3043783          	ld	a5,-464(s0)
    80005bc8:	c3b9                	beqz	a5,80005c0e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bca:	ffffb097          	auipc	ra,0xffffb
    80005bce:	f2a080e7          	jalr	-214(ra) # 80000af4 <kalloc>
    80005bd2:	85aa                	mv	a1,a0
    80005bd4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bd8:	cd11                	beqz	a0,80005bf4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bda:	6605                	lui	a2,0x1
    80005bdc:	e3043503          	ld	a0,-464(s0)
    80005be0:	ffffd097          	auipc	ra,0xffffd
    80005be4:	04e080e7          	jalr	78(ra) # 80002c2e <fetchstr>
    80005be8:	00054663          	bltz	a0,80005bf4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bec:	0905                	addi	s2,s2,1
    80005bee:	09a1                	addi	s3,s3,8
    80005bf0:	fb491be3          	bne	s2,s4,80005ba6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf4:	10048913          	addi	s2,s1,256
    80005bf8:	6088                	ld	a0,0(s1)
    80005bfa:	c529                	beqz	a0,80005c44 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bfc:	ffffb097          	auipc	ra,0xffffb
    80005c00:	dfc080e7          	jalr	-516(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c04:	04a1                	addi	s1,s1,8
    80005c06:	ff2499e3          	bne	s1,s2,80005bf8 <sys_exec+0xac>
  return -1;
    80005c0a:	597d                	li	s2,-1
    80005c0c:	a82d                	j	80005c46 <sys_exec+0xfa>
      argv[i] = 0;
    80005c0e:	0a8e                	slli	s5,s5,0x3
    80005c10:	fc040793          	addi	a5,s0,-64
    80005c14:	9abe                	add	s5,s5,a5
    80005c16:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c1a:	e4040593          	addi	a1,s0,-448
    80005c1e:	f4040513          	addi	a0,s0,-192
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	194080e7          	jalr	404(ra) # 80004db6 <exec>
    80005c2a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c2c:	10048993          	addi	s3,s1,256
    80005c30:	6088                	ld	a0,0(s1)
    80005c32:	c911                	beqz	a0,80005c46 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c34:	ffffb097          	auipc	ra,0xffffb
    80005c38:	dc4080e7          	jalr	-572(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c3c:	04a1                	addi	s1,s1,8
    80005c3e:	ff3499e3          	bne	s1,s3,80005c30 <sys_exec+0xe4>
    80005c42:	a011                	j	80005c46 <sys_exec+0xfa>
  return -1;
    80005c44:	597d                	li	s2,-1
}
    80005c46:	854a                	mv	a0,s2
    80005c48:	60be                	ld	ra,456(sp)
    80005c4a:	641e                	ld	s0,448(sp)
    80005c4c:	74fa                	ld	s1,440(sp)
    80005c4e:	795a                	ld	s2,432(sp)
    80005c50:	79ba                	ld	s3,424(sp)
    80005c52:	7a1a                	ld	s4,416(sp)
    80005c54:	6afa                	ld	s5,408(sp)
    80005c56:	6179                	addi	sp,sp,464
    80005c58:	8082                	ret

0000000080005c5a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c5a:	7139                	addi	sp,sp,-64
    80005c5c:	fc06                	sd	ra,56(sp)
    80005c5e:	f822                	sd	s0,48(sp)
    80005c60:	f426                	sd	s1,40(sp)
    80005c62:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c64:	ffffc097          	auipc	ra,0xffffc
    80005c68:	e10080e7          	jalr	-496(ra) # 80001a74 <myproc>
    80005c6c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c6e:	fd840593          	addi	a1,s0,-40
    80005c72:	4501                	li	a0,0
    80005c74:	ffffd097          	auipc	ra,0xffffd
    80005c78:	024080e7          	jalr	36(ra) # 80002c98 <argaddr>
    return -1;
    80005c7c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c7e:	0e054063          	bltz	a0,80005d5e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c82:	fc840593          	addi	a1,s0,-56
    80005c86:	fd040513          	addi	a0,s0,-48
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	dfc080e7          	jalr	-516(ra) # 80004a86 <pipealloc>
    return -1;
    80005c92:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c94:	0c054563          	bltz	a0,80005d5e <sys_pipe+0x104>
  fd0 = -1;
    80005c98:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c9c:	fd043503          	ld	a0,-48(s0)
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	508080e7          	jalr	1288(ra) # 800051a8 <fdalloc>
    80005ca8:	fca42223          	sw	a0,-60(s0)
    80005cac:	08054c63          	bltz	a0,80005d44 <sys_pipe+0xea>
    80005cb0:	fc843503          	ld	a0,-56(s0)
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	4f4080e7          	jalr	1268(ra) # 800051a8 <fdalloc>
    80005cbc:	fca42023          	sw	a0,-64(s0)
    80005cc0:	06054863          	bltz	a0,80005d30 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cc4:	4691                	li	a3,4
    80005cc6:	fc440613          	addi	a2,s0,-60
    80005cca:	fd843583          	ld	a1,-40(s0)
    80005cce:	68a8                	ld	a0,80(s1)
    80005cd0:	ffffc097          	auipc	ra,0xffffc
    80005cd4:	9a2080e7          	jalr	-1630(ra) # 80001672 <copyout>
    80005cd8:	02054063          	bltz	a0,80005cf8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cdc:	4691                	li	a3,4
    80005cde:	fc040613          	addi	a2,s0,-64
    80005ce2:	fd843583          	ld	a1,-40(s0)
    80005ce6:	0591                	addi	a1,a1,4
    80005ce8:	68a8                	ld	a0,80(s1)
    80005cea:	ffffc097          	auipc	ra,0xffffc
    80005cee:	988080e7          	jalr	-1656(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cf2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cf4:	06055563          	bgez	a0,80005d5e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cf8:	fc442783          	lw	a5,-60(s0)
    80005cfc:	07e9                	addi	a5,a5,26
    80005cfe:	078e                	slli	a5,a5,0x3
    80005d00:	97a6                	add	a5,a5,s1
    80005d02:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d06:	fc042503          	lw	a0,-64(s0)
    80005d0a:	0569                	addi	a0,a0,26
    80005d0c:	050e                	slli	a0,a0,0x3
    80005d0e:	9526                	add	a0,a0,s1
    80005d10:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d14:	fd043503          	ld	a0,-48(s0)
    80005d18:	fffff097          	auipc	ra,0xfffff
    80005d1c:	a3e080e7          	jalr	-1474(ra) # 80004756 <fileclose>
    fileclose(wf);
    80005d20:	fc843503          	ld	a0,-56(s0)
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	a32080e7          	jalr	-1486(ra) # 80004756 <fileclose>
    return -1;
    80005d2c:	57fd                	li	a5,-1
    80005d2e:	a805                	j	80005d5e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d30:	fc442783          	lw	a5,-60(s0)
    80005d34:	0007c863          	bltz	a5,80005d44 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d38:	01a78513          	addi	a0,a5,26
    80005d3c:	050e                	slli	a0,a0,0x3
    80005d3e:	9526                	add	a0,a0,s1
    80005d40:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d44:	fd043503          	ld	a0,-48(s0)
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	a0e080e7          	jalr	-1522(ra) # 80004756 <fileclose>
    fileclose(wf);
    80005d50:	fc843503          	ld	a0,-56(s0)
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	a02080e7          	jalr	-1534(ra) # 80004756 <fileclose>
    return -1;
    80005d5c:	57fd                	li	a5,-1
}
    80005d5e:	853e                	mv	a0,a5
    80005d60:	70e2                	ld	ra,56(sp)
    80005d62:	7442                	ld	s0,48(sp)
    80005d64:	74a2                	ld	s1,40(sp)
    80005d66:	6121                	addi	sp,sp,64
    80005d68:	8082                	ret
    80005d6a:	0000                	unimp
    80005d6c:	0000                	unimp
	...

0000000080005d70 <kernelvec>:
    80005d70:	7111                	addi	sp,sp,-256
    80005d72:	e006                	sd	ra,0(sp)
    80005d74:	e40a                	sd	sp,8(sp)
    80005d76:	e80e                	sd	gp,16(sp)
    80005d78:	ec12                	sd	tp,24(sp)
    80005d7a:	f016                	sd	t0,32(sp)
    80005d7c:	f41a                	sd	t1,40(sp)
    80005d7e:	f81e                	sd	t2,48(sp)
    80005d80:	fc22                	sd	s0,56(sp)
    80005d82:	e0a6                	sd	s1,64(sp)
    80005d84:	e4aa                	sd	a0,72(sp)
    80005d86:	e8ae                	sd	a1,80(sp)
    80005d88:	ecb2                	sd	a2,88(sp)
    80005d8a:	f0b6                	sd	a3,96(sp)
    80005d8c:	f4ba                	sd	a4,104(sp)
    80005d8e:	f8be                	sd	a5,112(sp)
    80005d90:	fcc2                	sd	a6,120(sp)
    80005d92:	e146                	sd	a7,128(sp)
    80005d94:	e54a                	sd	s2,136(sp)
    80005d96:	e94e                	sd	s3,144(sp)
    80005d98:	ed52                	sd	s4,152(sp)
    80005d9a:	f156                	sd	s5,160(sp)
    80005d9c:	f55a                	sd	s6,168(sp)
    80005d9e:	f95e                	sd	s7,176(sp)
    80005da0:	fd62                	sd	s8,184(sp)
    80005da2:	e1e6                	sd	s9,192(sp)
    80005da4:	e5ea                	sd	s10,200(sp)
    80005da6:	e9ee                	sd	s11,208(sp)
    80005da8:	edf2                	sd	t3,216(sp)
    80005daa:	f1f6                	sd	t4,224(sp)
    80005dac:	f5fa                	sd	t5,232(sp)
    80005dae:	f9fe                	sd	t6,240(sp)
    80005db0:	cf9fc0ef          	jal	ra,80002aa8 <kerneltrap>
    80005db4:	6082                	ld	ra,0(sp)
    80005db6:	6122                	ld	sp,8(sp)
    80005db8:	61c2                	ld	gp,16(sp)
    80005dba:	7282                	ld	t0,32(sp)
    80005dbc:	7322                	ld	t1,40(sp)
    80005dbe:	73c2                	ld	t2,48(sp)
    80005dc0:	7462                	ld	s0,56(sp)
    80005dc2:	6486                	ld	s1,64(sp)
    80005dc4:	6526                	ld	a0,72(sp)
    80005dc6:	65c6                	ld	a1,80(sp)
    80005dc8:	6666                	ld	a2,88(sp)
    80005dca:	7686                	ld	a3,96(sp)
    80005dcc:	7726                	ld	a4,104(sp)
    80005dce:	77c6                	ld	a5,112(sp)
    80005dd0:	7866                	ld	a6,120(sp)
    80005dd2:	688a                	ld	a7,128(sp)
    80005dd4:	692a                	ld	s2,136(sp)
    80005dd6:	69ca                	ld	s3,144(sp)
    80005dd8:	6a6a                	ld	s4,152(sp)
    80005dda:	7a8a                	ld	s5,160(sp)
    80005ddc:	7b2a                	ld	s6,168(sp)
    80005dde:	7bca                	ld	s7,176(sp)
    80005de0:	7c6a                	ld	s8,184(sp)
    80005de2:	6c8e                	ld	s9,192(sp)
    80005de4:	6d2e                	ld	s10,200(sp)
    80005de6:	6dce                	ld	s11,208(sp)
    80005de8:	6e6e                	ld	t3,216(sp)
    80005dea:	7e8e                	ld	t4,224(sp)
    80005dec:	7f2e                	ld	t5,232(sp)
    80005dee:	7fce                	ld	t6,240(sp)
    80005df0:	6111                	addi	sp,sp,256
    80005df2:	10200073          	sret
    80005df6:	00000013          	nop
    80005dfa:	00000013          	nop
    80005dfe:	0001                	nop

0000000080005e00 <timervec>:
    80005e00:	34051573          	csrrw	a0,mscratch,a0
    80005e04:	e10c                	sd	a1,0(a0)
    80005e06:	e510                	sd	a2,8(a0)
    80005e08:	e914                	sd	a3,16(a0)
    80005e0a:	6d0c                	ld	a1,24(a0)
    80005e0c:	7110                	ld	a2,32(a0)
    80005e0e:	6194                	ld	a3,0(a1)
    80005e10:	96b2                	add	a3,a3,a2
    80005e12:	e194                	sd	a3,0(a1)
    80005e14:	4589                	li	a1,2
    80005e16:	14459073          	csrw	sip,a1
    80005e1a:	6914                	ld	a3,16(a0)
    80005e1c:	6510                	ld	a2,8(a0)
    80005e1e:	610c                	ld	a1,0(a0)
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	30200073          	mret
	...

0000000080005e2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e2a:	1141                	addi	sp,sp,-16
    80005e2c:	e422                	sd	s0,8(sp)
    80005e2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e30:	0c0007b7          	lui	a5,0xc000
    80005e34:	4705                	li	a4,1
    80005e36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e38:	c3d8                	sw	a4,4(a5)
}
    80005e3a:	6422                	ld	s0,8(sp)
    80005e3c:	0141                	addi	sp,sp,16
    80005e3e:	8082                	ret

0000000080005e40 <plicinithart>:

void
plicinithart(void)
{
    80005e40:	1141                	addi	sp,sp,-16
    80005e42:	e406                	sd	ra,8(sp)
    80005e44:	e022                	sd	s0,0(sp)
    80005e46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	c00080e7          	jalr	-1024(ra) # 80001a48 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e50:	0085171b          	slliw	a4,a0,0x8
    80005e54:	0c0027b7          	lui	a5,0xc002
    80005e58:	97ba                	add	a5,a5,a4
    80005e5a:	40200713          	li	a4,1026
    80005e5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e62:	00d5151b          	slliw	a0,a0,0xd
    80005e66:	0c2017b7          	lui	a5,0xc201
    80005e6a:	953e                	add	a0,a0,a5
    80005e6c:	00052023          	sw	zero,0(a0)
}
    80005e70:	60a2                	ld	ra,8(sp)
    80005e72:	6402                	ld	s0,0(sp)
    80005e74:	0141                	addi	sp,sp,16
    80005e76:	8082                	ret

0000000080005e78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e78:	1141                	addi	sp,sp,-16
    80005e7a:	e406                	sd	ra,8(sp)
    80005e7c:	e022                	sd	s0,0(sp)
    80005e7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e80:	ffffc097          	auipc	ra,0xffffc
    80005e84:	bc8080e7          	jalr	-1080(ra) # 80001a48 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e88:	00d5179b          	slliw	a5,a0,0xd
    80005e8c:	0c201537          	lui	a0,0xc201
    80005e90:	953e                	add	a0,a0,a5
  return irq;
}
    80005e92:	4148                	lw	a0,4(a0)
    80005e94:	60a2                	ld	ra,8(sp)
    80005e96:	6402                	ld	s0,0(sp)
    80005e98:	0141                	addi	sp,sp,16
    80005e9a:	8082                	ret

0000000080005e9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e9c:	1101                	addi	sp,sp,-32
    80005e9e:	ec06                	sd	ra,24(sp)
    80005ea0:	e822                	sd	s0,16(sp)
    80005ea2:	e426                	sd	s1,8(sp)
    80005ea4:	1000                	addi	s0,sp,32
    80005ea6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ea8:	ffffc097          	auipc	ra,0xffffc
    80005eac:	ba0080e7          	jalr	-1120(ra) # 80001a48 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005eb0:	00d5151b          	slliw	a0,a0,0xd
    80005eb4:	0c2017b7          	lui	a5,0xc201
    80005eb8:	97aa                	add	a5,a5,a0
    80005eba:	c3c4                	sw	s1,4(a5)
}
    80005ebc:	60e2                	ld	ra,24(sp)
    80005ebe:	6442                	ld	s0,16(sp)
    80005ec0:	64a2                	ld	s1,8(sp)
    80005ec2:	6105                	addi	sp,sp,32
    80005ec4:	8082                	ret

0000000080005ec6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ec6:	1141                	addi	sp,sp,-16
    80005ec8:	e406                	sd	ra,8(sp)
    80005eca:	e022                	sd	s0,0(sp)
    80005ecc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ece:	479d                	li	a5,7
    80005ed0:	06a7c963          	blt	a5,a0,80005f42 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ed4:	0001d797          	auipc	a5,0x1d
    80005ed8:	12c78793          	addi	a5,a5,300 # 80023000 <disk>
    80005edc:	00a78733          	add	a4,a5,a0
    80005ee0:	6789                	lui	a5,0x2
    80005ee2:	97ba                	add	a5,a5,a4
    80005ee4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ee8:	e7ad                	bnez	a5,80005f52 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005eea:	00451793          	slli	a5,a0,0x4
    80005eee:	0001f717          	auipc	a4,0x1f
    80005ef2:	11270713          	addi	a4,a4,274 # 80025000 <disk+0x2000>
    80005ef6:	6314                	ld	a3,0(a4)
    80005ef8:	96be                	add	a3,a3,a5
    80005efa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005efe:	6314                	ld	a3,0(a4)
    80005f00:	96be                	add	a3,a3,a5
    80005f02:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f06:	6314                	ld	a3,0(a4)
    80005f08:	96be                	add	a3,a3,a5
    80005f0a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f0e:	6318                	ld	a4,0(a4)
    80005f10:	97ba                	add	a5,a5,a4
    80005f12:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f16:	0001d797          	auipc	a5,0x1d
    80005f1a:	0ea78793          	addi	a5,a5,234 # 80023000 <disk>
    80005f1e:	97aa                	add	a5,a5,a0
    80005f20:	6509                	lui	a0,0x2
    80005f22:	953e                	add	a0,a0,a5
    80005f24:	4785                	li	a5,1
    80005f26:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f2a:	0001f517          	auipc	a0,0x1f
    80005f2e:	0ee50513          	addi	a0,a0,238 # 80025018 <disk+0x2018>
    80005f32:	ffffc097          	auipc	ra,0xffffc
    80005f36:	4e0080e7          	jalr	1248(ra) # 80002412 <wakeup>
}
    80005f3a:	60a2                	ld	ra,8(sp)
    80005f3c:	6402                	ld	s0,0(sp)
    80005f3e:	0141                	addi	sp,sp,16
    80005f40:	8082                	ret
    panic("free_desc 1");
    80005f42:	00003517          	auipc	a0,0x3
    80005f46:	95e50513          	addi	a0,a0,-1698 # 800088a0 <syscalls+0x380>
    80005f4a:	ffffa097          	auipc	ra,0xffffa
    80005f4e:	5f4080e7          	jalr	1524(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f52:	00003517          	auipc	a0,0x3
    80005f56:	95e50513          	addi	a0,a0,-1698 # 800088b0 <syscalls+0x390>
    80005f5a:	ffffa097          	auipc	ra,0xffffa
    80005f5e:	5e4080e7          	jalr	1508(ra) # 8000053e <panic>

0000000080005f62 <virtio_disk_init>:
{
    80005f62:	1101                	addi	sp,sp,-32
    80005f64:	ec06                	sd	ra,24(sp)
    80005f66:	e822                	sd	s0,16(sp)
    80005f68:	e426                	sd	s1,8(sp)
    80005f6a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f6c:	00003597          	auipc	a1,0x3
    80005f70:	95458593          	addi	a1,a1,-1708 # 800088c0 <syscalls+0x3a0>
    80005f74:	0001f517          	auipc	a0,0x1f
    80005f78:	1b450513          	addi	a0,a0,436 # 80025128 <disk+0x2128>
    80005f7c:	ffffb097          	auipc	ra,0xffffb
    80005f80:	bd8080e7          	jalr	-1064(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f84:	100017b7          	lui	a5,0x10001
    80005f88:	4398                	lw	a4,0(a5)
    80005f8a:	2701                	sext.w	a4,a4
    80005f8c:	747277b7          	lui	a5,0x74727
    80005f90:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f94:	0ef71163          	bne	a4,a5,80006076 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f98:	100017b7          	lui	a5,0x10001
    80005f9c:	43dc                	lw	a5,4(a5)
    80005f9e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa0:	4705                	li	a4,1
    80005fa2:	0ce79a63          	bne	a5,a4,80006076 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fa6:	100017b7          	lui	a5,0x10001
    80005faa:	479c                	lw	a5,8(a5)
    80005fac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fae:	4709                	li	a4,2
    80005fb0:	0ce79363          	bne	a5,a4,80006076 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fb4:	100017b7          	lui	a5,0x10001
    80005fb8:	47d8                	lw	a4,12(a5)
    80005fba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fbc:	554d47b7          	lui	a5,0x554d4
    80005fc0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fc4:	0af71963          	bne	a4,a5,80006076 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc8:	100017b7          	lui	a5,0x10001
    80005fcc:	4705                	li	a4,1
    80005fce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd0:	470d                	li	a4,3
    80005fd2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fd4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fd6:	c7ffe737          	lui	a4,0xc7ffe
    80005fda:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005fde:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fe0:	2701                	sext.w	a4,a4
    80005fe2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe4:	472d                	li	a4,11
    80005fe6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe8:	473d                	li	a4,15
    80005fea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fec:	6705                	lui	a4,0x1
    80005fee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ff0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ff4:	5bdc                	lw	a5,52(a5)
    80005ff6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ff8:	c7d9                	beqz	a5,80006086 <virtio_disk_init+0x124>
  if(max < NUM)
    80005ffa:	471d                	li	a4,7
    80005ffc:	08f77d63          	bgeu	a4,a5,80006096 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006000:	100014b7          	lui	s1,0x10001
    80006004:	47a1                	li	a5,8
    80006006:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006008:	6609                	lui	a2,0x2
    8000600a:	4581                	li	a1,0
    8000600c:	0001d517          	auipc	a0,0x1d
    80006010:	ff450513          	addi	a0,a0,-12 # 80023000 <disk>
    80006014:	ffffb097          	auipc	ra,0xffffb
    80006018:	ccc080e7          	jalr	-820(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000601c:	0001d717          	auipc	a4,0x1d
    80006020:	fe470713          	addi	a4,a4,-28 # 80023000 <disk>
    80006024:	00c75793          	srli	a5,a4,0xc
    80006028:	2781                	sext.w	a5,a5
    8000602a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000602c:	0001f797          	auipc	a5,0x1f
    80006030:	fd478793          	addi	a5,a5,-44 # 80025000 <disk+0x2000>
    80006034:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006036:	0001d717          	auipc	a4,0x1d
    8000603a:	04a70713          	addi	a4,a4,74 # 80023080 <disk+0x80>
    8000603e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006040:	0001e717          	auipc	a4,0x1e
    80006044:	fc070713          	addi	a4,a4,-64 # 80024000 <disk+0x1000>
    80006048:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000604a:	4705                	li	a4,1
    8000604c:	00e78c23          	sb	a4,24(a5)
    80006050:	00e78ca3          	sb	a4,25(a5)
    80006054:	00e78d23          	sb	a4,26(a5)
    80006058:	00e78da3          	sb	a4,27(a5)
    8000605c:	00e78e23          	sb	a4,28(a5)
    80006060:	00e78ea3          	sb	a4,29(a5)
    80006064:	00e78f23          	sb	a4,30(a5)
    80006068:	00e78fa3          	sb	a4,31(a5)
}
    8000606c:	60e2                	ld	ra,24(sp)
    8000606e:	6442                	ld	s0,16(sp)
    80006070:	64a2                	ld	s1,8(sp)
    80006072:	6105                	addi	sp,sp,32
    80006074:	8082                	ret
    panic("could not find virtio disk");
    80006076:	00003517          	auipc	a0,0x3
    8000607a:	85a50513          	addi	a0,a0,-1958 # 800088d0 <syscalls+0x3b0>
    8000607e:	ffffa097          	auipc	ra,0xffffa
    80006082:	4c0080e7          	jalr	1216(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006086:	00003517          	auipc	a0,0x3
    8000608a:	86a50513          	addi	a0,a0,-1942 # 800088f0 <syscalls+0x3d0>
    8000608e:	ffffa097          	auipc	ra,0xffffa
    80006092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006096:	00003517          	auipc	a0,0x3
    8000609a:	87a50513          	addi	a0,a0,-1926 # 80008910 <syscalls+0x3f0>
    8000609e:	ffffa097          	auipc	ra,0xffffa
    800060a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>

00000000800060a6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060a6:	7159                	addi	sp,sp,-112
    800060a8:	f486                	sd	ra,104(sp)
    800060aa:	f0a2                	sd	s0,96(sp)
    800060ac:	eca6                	sd	s1,88(sp)
    800060ae:	e8ca                	sd	s2,80(sp)
    800060b0:	e4ce                	sd	s3,72(sp)
    800060b2:	e0d2                	sd	s4,64(sp)
    800060b4:	fc56                	sd	s5,56(sp)
    800060b6:	f85a                	sd	s6,48(sp)
    800060b8:	f45e                	sd	s7,40(sp)
    800060ba:	f062                	sd	s8,32(sp)
    800060bc:	ec66                	sd	s9,24(sp)
    800060be:	e86a                	sd	s10,16(sp)
    800060c0:	1880                	addi	s0,sp,112
    800060c2:	892a                	mv	s2,a0
    800060c4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060c6:	00c52c83          	lw	s9,12(a0)
    800060ca:	001c9c9b          	slliw	s9,s9,0x1
    800060ce:	1c82                	slli	s9,s9,0x20
    800060d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060d4:	0001f517          	auipc	a0,0x1f
    800060d8:	05450513          	addi	a0,a0,84 # 80025128 <disk+0x2128>
    800060dc:	ffffb097          	auipc	ra,0xffffb
    800060e0:	b08080e7          	jalr	-1272(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800060e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060e6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060e8:	0001db97          	auipc	s7,0x1d
    800060ec:	f18b8b93          	addi	s7,s7,-232 # 80023000 <disk>
    800060f0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060f2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060f4:	8a4e                	mv	s4,s3
    800060f6:	a051                	j	8000617a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060f8:	00fb86b3          	add	a3,s7,a5
    800060fc:	96da                	add	a3,a3,s6
    800060fe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006102:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006104:	0207c563          	bltz	a5,8000612e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006108:	2485                	addiw	s1,s1,1
    8000610a:	0711                	addi	a4,a4,4
    8000610c:	25548063          	beq	s1,s5,8000634c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006110:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006112:	0001f697          	auipc	a3,0x1f
    80006116:	f0668693          	addi	a3,a3,-250 # 80025018 <disk+0x2018>
    8000611a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000611c:	0006c583          	lbu	a1,0(a3)
    80006120:	fde1                	bnez	a1,800060f8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006122:	2785                	addiw	a5,a5,1
    80006124:	0685                	addi	a3,a3,1
    80006126:	ff879be3          	bne	a5,s8,8000611c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000612a:	57fd                	li	a5,-1
    8000612c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000612e:	02905a63          	blez	s1,80006162 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006132:	f9042503          	lw	a0,-112(s0)
    80006136:	00000097          	auipc	ra,0x0
    8000613a:	d90080e7          	jalr	-624(ra) # 80005ec6 <free_desc>
      for(int j = 0; j < i; j++)
    8000613e:	4785                	li	a5,1
    80006140:	0297d163          	bge	a5,s1,80006162 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006144:	f9442503          	lw	a0,-108(s0)
    80006148:	00000097          	auipc	ra,0x0
    8000614c:	d7e080e7          	jalr	-642(ra) # 80005ec6 <free_desc>
      for(int j = 0; j < i; j++)
    80006150:	4789                	li	a5,2
    80006152:	0097d863          	bge	a5,s1,80006162 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006156:	f9842503          	lw	a0,-104(s0)
    8000615a:	00000097          	auipc	ra,0x0
    8000615e:	d6c080e7          	jalr	-660(ra) # 80005ec6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006162:	0001f597          	auipc	a1,0x1f
    80006166:	fc658593          	addi	a1,a1,-58 # 80025128 <disk+0x2128>
    8000616a:	0001f517          	auipc	a0,0x1f
    8000616e:	eae50513          	addi	a0,a0,-338 # 80025018 <disk+0x2018>
    80006172:	ffffc097          	auipc	ra,0xffffc
    80006176:	114080e7          	jalr	276(ra) # 80002286 <sleep>
  for(int i = 0; i < 3; i++){
    8000617a:	f9040713          	addi	a4,s0,-112
    8000617e:	84ce                	mv	s1,s3
    80006180:	bf41                	j	80006110 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006182:	20058713          	addi	a4,a1,512
    80006186:	00471693          	slli	a3,a4,0x4
    8000618a:	0001d717          	auipc	a4,0x1d
    8000618e:	e7670713          	addi	a4,a4,-394 # 80023000 <disk>
    80006192:	9736                	add	a4,a4,a3
    80006194:	4685                	li	a3,1
    80006196:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000619a:	20058713          	addi	a4,a1,512
    8000619e:	00471693          	slli	a3,a4,0x4
    800061a2:	0001d717          	auipc	a4,0x1d
    800061a6:	e5e70713          	addi	a4,a4,-418 # 80023000 <disk>
    800061aa:	9736                	add	a4,a4,a3
    800061ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061b4:	7679                	lui	a2,0xffffe
    800061b6:	963e                	add	a2,a2,a5
    800061b8:	0001f697          	auipc	a3,0x1f
    800061bc:	e4868693          	addi	a3,a3,-440 # 80025000 <disk+0x2000>
    800061c0:	6298                	ld	a4,0(a3)
    800061c2:	9732                	add	a4,a4,a2
    800061c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061c6:	6298                	ld	a4,0(a3)
    800061c8:	9732                	add	a4,a4,a2
    800061ca:	4541                	li	a0,16
    800061cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061ce:	6298                	ld	a4,0(a3)
    800061d0:	9732                	add	a4,a4,a2
    800061d2:	4505                	li	a0,1
    800061d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061d8:	f9442703          	lw	a4,-108(s0)
    800061dc:	6288                	ld	a0,0(a3)
    800061de:	962a                	add	a2,a2,a0
    800061e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061e4:	0712                	slli	a4,a4,0x4
    800061e6:	6290                	ld	a2,0(a3)
    800061e8:	963a                	add	a2,a2,a4
    800061ea:	05890513          	addi	a0,s2,88
    800061ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061f0:	6294                	ld	a3,0(a3)
    800061f2:	96ba                	add	a3,a3,a4
    800061f4:	40000613          	li	a2,1024
    800061f8:	c690                	sw	a2,8(a3)
  if(write)
    800061fa:	140d0063          	beqz	s10,8000633a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061fe:	0001f697          	auipc	a3,0x1f
    80006202:	e026b683          	ld	a3,-510(a3) # 80025000 <disk+0x2000>
    80006206:	96ba                	add	a3,a3,a4
    80006208:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000620c:	0001d817          	auipc	a6,0x1d
    80006210:	df480813          	addi	a6,a6,-524 # 80023000 <disk>
    80006214:	0001f517          	auipc	a0,0x1f
    80006218:	dec50513          	addi	a0,a0,-532 # 80025000 <disk+0x2000>
    8000621c:	6114                	ld	a3,0(a0)
    8000621e:	96ba                	add	a3,a3,a4
    80006220:	00c6d603          	lhu	a2,12(a3)
    80006224:	00166613          	ori	a2,a2,1
    80006228:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000622c:	f9842683          	lw	a3,-104(s0)
    80006230:	6110                	ld	a2,0(a0)
    80006232:	9732                	add	a4,a4,a2
    80006234:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006238:	20058613          	addi	a2,a1,512
    8000623c:	0612                	slli	a2,a2,0x4
    8000623e:	9642                	add	a2,a2,a6
    80006240:	577d                	li	a4,-1
    80006242:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006246:	00469713          	slli	a4,a3,0x4
    8000624a:	6114                	ld	a3,0(a0)
    8000624c:	96ba                	add	a3,a3,a4
    8000624e:	03078793          	addi	a5,a5,48
    80006252:	97c2                	add	a5,a5,a6
    80006254:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006256:	611c                	ld	a5,0(a0)
    80006258:	97ba                	add	a5,a5,a4
    8000625a:	4685                	li	a3,1
    8000625c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000625e:	611c                	ld	a5,0(a0)
    80006260:	97ba                	add	a5,a5,a4
    80006262:	4809                	li	a6,2
    80006264:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006268:	611c                	ld	a5,0(a0)
    8000626a:	973e                	add	a4,a4,a5
    8000626c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006270:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006274:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006278:	6518                	ld	a4,8(a0)
    8000627a:	00275783          	lhu	a5,2(a4)
    8000627e:	8b9d                	andi	a5,a5,7
    80006280:	0786                	slli	a5,a5,0x1
    80006282:	97ba                	add	a5,a5,a4
    80006284:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006288:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000628c:	6518                	ld	a4,8(a0)
    8000628e:	00275783          	lhu	a5,2(a4)
    80006292:	2785                	addiw	a5,a5,1
    80006294:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006298:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000629c:	100017b7          	lui	a5,0x10001
    800062a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062a4:	00492703          	lw	a4,4(s2)
    800062a8:	4785                	li	a5,1
    800062aa:	02f71163          	bne	a4,a5,800062cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062ae:	0001f997          	auipc	s3,0x1f
    800062b2:	e7a98993          	addi	s3,s3,-390 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800062b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062b8:	85ce                	mv	a1,s3
    800062ba:	854a                	mv	a0,s2
    800062bc:	ffffc097          	auipc	ra,0xffffc
    800062c0:	fca080e7          	jalr	-54(ra) # 80002286 <sleep>
  while(b->disk == 1) {
    800062c4:	00492783          	lw	a5,4(s2)
    800062c8:	fe9788e3          	beq	a5,s1,800062b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062cc:	f9042903          	lw	s2,-112(s0)
    800062d0:	20090793          	addi	a5,s2,512
    800062d4:	00479713          	slli	a4,a5,0x4
    800062d8:	0001d797          	auipc	a5,0x1d
    800062dc:	d2878793          	addi	a5,a5,-728 # 80023000 <disk>
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062e6:	0001f997          	auipc	s3,0x1f
    800062ea:	d1a98993          	addi	s3,s3,-742 # 80025000 <disk+0x2000>
    800062ee:	00491713          	slli	a4,s2,0x4
    800062f2:	0009b783          	ld	a5,0(s3)
    800062f6:	97ba                	add	a5,a5,a4
    800062f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062fc:	854a                	mv	a0,s2
    800062fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006302:	00000097          	auipc	ra,0x0
    80006306:	bc4080e7          	jalr	-1084(ra) # 80005ec6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000630a:	8885                	andi	s1,s1,1
    8000630c:	f0ed                	bnez	s1,800062ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000630e:	0001f517          	auipc	a0,0x1f
    80006312:	e1a50513          	addi	a0,a0,-486 # 80025128 <disk+0x2128>
    80006316:	ffffb097          	auipc	ra,0xffffb
    8000631a:	982080e7          	jalr	-1662(ra) # 80000c98 <release>
}
    8000631e:	70a6                	ld	ra,104(sp)
    80006320:	7406                	ld	s0,96(sp)
    80006322:	64e6                	ld	s1,88(sp)
    80006324:	6946                	ld	s2,80(sp)
    80006326:	69a6                	ld	s3,72(sp)
    80006328:	6a06                	ld	s4,64(sp)
    8000632a:	7ae2                	ld	s5,56(sp)
    8000632c:	7b42                	ld	s6,48(sp)
    8000632e:	7ba2                	ld	s7,40(sp)
    80006330:	7c02                	ld	s8,32(sp)
    80006332:	6ce2                	ld	s9,24(sp)
    80006334:	6d42                	ld	s10,16(sp)
    80006336:	6165                	addi	sp,sp,112
    80006338:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000633a:	0001f697          	auipc	a3,0x1f
    8000633e:	cc66b683          	ld	a3,-826(a3) # 80025000 <disk+0x2000>
    80006342:	96ba                	add	a3,a3,a4
    80006344:	4609                	li	a2,2
    80006346:	00c69623          	sh	a2,12(a3)
    8000634a:	b5c9                	j	8000620c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000634c:	f9042583          	lw	a1,-112(s0)
    80006350:	20058793          	addi	a5,a1,512
    80006354:	0792                	slli	a5,a5,0x4
    80006356:	0001d517          	auipc	a0,0x1d
    8000635a:	d5250513          	addi	a0,a0,-686 # 800230a8 <disk+0xa8>
    8000635e:	953e                	add	a0,a0,a5
  if(write)
    80006360:	e20d11e3          	bnez	s10,80006182 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006364:	20058713          	addi	a4,a1,512
    80006368:	00471693          	slli	a3,a4,0x4
    8000636c:	0001d717          	auipc	a4,0x1d
    80006370:	c9470713          	addi	a4,a4,-876 # 80023000 <disk>
    80006374:	9736                	add	a4,a4,a3
    80006376:	0a072423          	sw	zero,168(a4)
    8000637a:	b505                	j	8000619a <virtio_disk_rw+0xf4>

000000008000637c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000637c:	1101                	addi	sp,sp,-32
    8000637e:	ec06                	sd	ra,24(sp)
    80006380:	e822                	sd	s0,16(sp)
    80006382:	e426                	sd	s1,8(sp)
    80006384:	e04a                	sd	s2,0(sp)
    80006386:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006388:	0001f517          	auipc	a0,0x1f
    8000638c:	da050513          	addi	a0,a0,-608 # 80025128 <disk+0x2128>
    80006390:	ffffb097          	auipc	ra,0xffffb
    80006394:	854080e7          	jalr	-1964(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006398:	10001737          	lui	a4,0x10001
    8000639c:	533c                	lw	a5,96(a4)
    8000639e:	8b8d                	andi	a5,a5,3
    800063a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063a6:	0001f797          	auipc	a5,0x1f
    800063aa:	c5a78793          	addi	a5,a5,-934 # 80025000 <disk+0x2000>
    800063ae:	6b94                	ld	a3,16(a5)
    800063b0:	0207d703          	lhu	a4,32(a5)
    800063b4:	0026d783          	lhu	a5,2(a3)
    800063b8:	06f70163          	beq	a4,a5,8000641a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063bc:	0001d917          	auipc	s2,0x1d
    800063c0:	c4490913          	addi	s2,s2,-956 # 80023000 <disk>
    800063c4:	0001f497          	auipc	s1,0x1f
    800063c8:	c3c48493          	addi	s1,s1,-964 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063d0:	6898                	ld	a4,16(s1)
    800063d2:	0204d783          	lhu	a5,32(s1)
    800063d6:	8b9d                	andi	a5,a5,7
    800063d8:	078e                	slli	a5,a5,0x3
    800063da:	97ba                	add	a5,a5,a4
    800063dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063de:	20078713          	addi	a4,a5,512
    800063e2:	0712                	slli	a4,a4,0x4
    800063e4:	974a                	add	a4,a4,s2
    800063e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063ea:	e731                	bnez	a4,80006436 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063ec:	20078793          	addi	a5,a5,512
    800063f0:	0792                	slli	a5,a5,0x4
    800063f2:	97ca                	add	a5,a5,s2
    800063f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063fa:	ffffc097          	auipc	ra,0xffffc
    800063fe:	018080e7          	jalr	24(ra) # 80002412 <wakeup>

    disk.used_idx += 1;
    80006402:	0204d783          	lhu	a5,32(s1)
    80006406:	2785                	addiw	a5,a5,1
    80006408:	17c2                	slli	a5,a5,0x30
    8000640a:	93c1                	srli	a5,a5,0x30
    8000640c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006410:	6898                	ld	a4,16(s1)
    80006412:	00275703          	lhu	a4,2(a4)
    80006416:	faf71be3          	bne	a4,a5,800063cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000641a:	0001f517          	auipc	a0,0x1f
    8000641e:	d0e50513          	addi	a0,a0,-754 # 80025128 <disk+0x2128>
    80006422:	ffffb097          	auipc	ra,0xffffb
    80006426:	876080e7          	jalr	-1930(ra) # 80000c98 <release>
}
    8000642a:	60e2                	ld	ra,24(sp)
    8000642c:	6442                	ld	s0,16(sp)
    8000642e:	64a2                	ld	s1,8(sp)
    80006430:	6902                	ld	s2,0(sp)
    80006432:	6105                	addi	sp,sp,32
    80006434:	8082                	ret
      panic("virtio_disk_intr status");
    80006436:	00002517          	auipc	a0,0x2
    8000643a:	4fa50513          	addi	a0,a0,1274 # 80008930 <syscalls+0x410>
    8000643e:	ffffa097          	auipc	ra,0xffffa
    80006442:	100080e7          	jalr	256(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
