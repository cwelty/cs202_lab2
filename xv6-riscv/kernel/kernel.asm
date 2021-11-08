
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	bde78793          	addi	a5,a5,-1058 # 80005c40 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	3d0080e7          	jalr	976(ra) # 800024fa <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	84c080e7          	jalr	-1972(ra) # 80001a0c <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	f30080e7          	jalr	-208(ra) # 80002100 <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	298080e7          	jalr	664(ra) # 800024a4 <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	264080e7          	jalr	612(ra) # 80002550 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	e4c080e7          	jalr	-436(ra) # 8000228c <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	0a678793          	addi	a5,a5,166 # 80021518 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	9fe080e7          	jalr	-1538(ra) # 8000228c <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	7e6080e7          	jalr	2022(ra) # 80002100 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00025797          	auipc	a5,0x25
    800009fa:	60a78793          	addi	a5,a5,1546 # 80026000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e86080e7          	jalr	-378(ra) # 800019f0 <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	e54080e7          	jalr	-428(ra) # 800019f0 <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	e48080e7          	jalr	-440(ra) # 800019f0 <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	e30080e7          	jalr	-464(ra) # 800019f0 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	df0080e7          	jalr	-528(ra) # 800019f0 <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	dc4080e7          	jalr	-572(ra) # 800019f0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4) # ffffffffffffefff <end+0xffffffff7ffd8fff>
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	b66080e7          	jalr	-1178(ra) # 800019e0 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b4a080e7          	jalr	-1206(ra) # 800019e0 <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	7da080e7          	jalr	2010(ra) # 80002692 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	dc0080e7          	jalr	-576(ra) # 80005c80 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	086080e7          	jalr	134(ra) # 80001f4e <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	a08080e7          	jalr	-1528(ra) # 80001930 <procinit>
    trapinit();      // trap vectors
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	73a080e7          	jalr	1850(ra) # 8000266a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	75a080e7          	jalr	1882(ra) # 80002692 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	d2a080e7          	jalr	-726(ra) # 80005c6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	d38080e7          	jalr	-712(ra) # 80005c80 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	ef6080e7          	jalr	-266(ra) # 80002e46 <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	584080e7          	jalr	1412(ra) # 800034dc <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	536080e7          	jalr	1334(ra) # 80004496 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	e38080e7          	jalr	-456(ra) # 80005da0 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	da4080e7          	jalr	-604(ra) # 80001d14 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1
    80001852:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00016a17          	auipc	s4,0x16
    80001858:	a7ca0a13          	addi	s4,s4,-1412 # 800172d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	8591                	srai	a1,a1,0x4
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	17048493          	addi	s1,s1,368
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c88080e7          	jalr	-888(ra) # 8000053a <panic>

00000000800018ba <process_count_print>:
	struct proc *p = myproc();
	int syscallCount = p->syscallCount;
	printf("Number of system calls made by the current process: %d\n", syscallCount);
}

void process_count_print(void){
    800018ba:	1141                	addi	sp,sp,-16
    800018bc:	e406                	sd	ra,8(sp)
    800018be:	e022                	sd	s0,0(sp)
    800018c0:	0800                	addi	s0,sp,16
  struct proc *p;
  int count = 0;
    800018c2:	4581                	li	a1,0
  for(p = proc; p < &proc[NPROC]; p++){
    800018c4:	00010797          	auipc	a5,0x10
    800018c8:	e0c78793          	addi	a5,a5,-500 # 800116d0 <proc>
    800018cc:	00016697          	auipc	a3,0x16
    800018d0:	a0468693          	addi	a3,a3,-1532 # 800172d0 <tickslock>
    800018d4:	a029                	j	800018de <process_count_print+0x24>
    800018d6:	17078793          	addi	a5,a5,368
    800018da:	00d78663          	beq	a5,a3,800018e6 <process_count_print+0x2c>
    if(p->state == UNUSED)
    800018de:	4f98                	lw	a4,24(a5)
    800018e0:	db7d                	beqz	a4,800018d6 <process_count_print+0x1c>
      continue;
    count++;
    800018e2:	2585                	addiw	a1,a1,1
    800018e4:	bfcd                	j	800018d6 <process_count_print+0x1c>
  }

  printf("Number of processes in the system: %d\n", count); 
    800018e6:	00007517          	auipc	a0,0x7
    800018ea:	8fa50513          	addi	a0,a0,-1798 # 800081e0 <digits+0x1a0>
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	c96080e7          	jalr	-874(ra) # 80000584 <printf>

}
    800018f6:	60a2                	ld	ra,8(sp)
    800018f8:	6402                	ld	s0,0(sp)
    800018fa:	0141                	addi	sp,sp,16
    800018fc:	8082                	ret

00000000800018fe <mem_pages_count_print>:

void mem_pages_count_print(void){
    800018fe:	1141                	addi	sp,sp,-16
    80001900:	e406                	sd	ra,8(sp)
    80001902:	e022                	sd	s0,0(sp)
    80001904:	0800                	addi	s0,sp,16
  uint memPagesCount = (PGROUNDUP(proc->sz)) / PGSIZE;
    80001906:	00010597          	auipc	a1,0x10
    8000190a:	e125b583          	ld	a1,-494(a1) # 80011718 <proc+0x48>
    8000190e:	6785                	lui	a5,0x1
    80001910:	17fd                	addi	a5,a5,-1
    80001912:	95be                	add	a1,a1,a5
    80001914:	81b1                	srli	a1,a1,0xc
  printf("Number of memory pages: %d\n", memPagesCount);
    80001916:	2581                	sext.w	a1,a1
    80001918:	00007517          	auipc	a0,0x7
    8000191c:	8f050513          	addi	a0,a0,-1808 # 80008208 <digits+0x1c8>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	c64080e7          	jalr	-924(ra) # 80000584 <printf>
}
    80001928:	60a2                	ld	ra,8(sp)
    8000192a:	6402                	ld	s0,0(sp)
    8000192c:	0141                	addi	sp,sp,16
    8000192e:	8082                	ret

0000000080001930 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001930:	7139                	addi	sp,sp,-64
    80001932:	fc06                	sd	ra,56(sp)
    80001934:	f822                	sd	s0,48(sp)
    80001936:	f426                	sd	s1,40(sp)
    80001938:	f04a                	sd	s2,32(sp)
    8000193a:	ec4e                	sd	s3,24(sp)
    8000193c:	e852                	sd	s4,16(sp)
    8000193e:	e456                	sd	s5,8(sp)
    80001940:	e05a                	sd	s6,0(sp)
    80001942:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001944:	00007597          	auipc	a1,0x7
    80001948:	8e458593          	addi	a1,a1,-1820 # 80008228 <digits+0x1e8>
    8000194c:	00010517          	auipc	a0,0x10
    80001950:	95450513          	addi	a0,a0,-1708 # 800112a0 <pid_lock>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	1ec080e7          	jalr	492(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000195c:	00007597          	auipc	a1,0x7
    80001960:	8d458593          	addi	a1,a1,-1836 # 80008230 <digits+0x1f0>
    80001964:	00010517          	auipc	a0,0x10
    80001968:	95450513          	addi	a0,a0,-1708 # 800112b8 <wait_lock>
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	1d4080e7          	jalr	468(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001974:	00010497          	auipc	s1,0x10
    80001978:	d5c48493          	addi	s1,s1,-676 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    8000197c:	00007b17          	auipc	s6,0x7
    80001980:	8c4b0b13          	addi	s6,s6,-1852 # 80008240 <digits+0x200>
      p->kstack = KSTACK((int) (p - proc));
    80001984:	8aa6                	mv	s5,s1
    80001986:	00006a17          	auipc	s4,0x6
    8000198a:	67aa0a13          	addi	s4,s4,1658 # 80008000 <etext>
    8000198e:	04000937          	lui	s2,0x4000
    80001992:	197d                	addi	s2,s2,-1
    80001994:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001996:	00016997          	auipc	s3,0x16
    8000199a:	93a98993          	addi	s3,s3,-1734 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    8000199e:	85da                	mv	a1,s6
    800019a0:	8526                	mv	a0,s1
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	19e080e7          	jalr	414(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019aa:	415487b3          	sub	a5,s1,s5
    800019ae:	8791                	srai	a5,a5,0x4
    800019b0:	000a3703          	ld	a4,0(s4)
    800019b4:	02e787b3          	mul	a5,a5,a4
    800019b8:	2785                	addiw	a5,a5,1
    800019ba:	00d7979b          	slliw	a5,a5,0xd
    800019be:	40f907b3          	sub	a5,s2,a5
    800019c2:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c4:	17048493          	addi	s1,s1,368
    800019c8:	fd349be3          	bne	s1,s3,8000199e <procinit+0x6e>
  }
}
    800019cc:	70e2                	ld	ra,56(sp)
    800019ce:	7442                	ld	s0,48(sp)
    800019d0:	74a2                	ld	s1,40(sp)
    800019d2:	7902                	ld	s2,32(sp)
    800019d4:	69e2                	ld	s3,24(sp)
    800019d6:	6a42                	ld	s4,16(sp)
    800019d8:	6aa2                	ld	s5,8(sp)
    800019da:	6b02                	ld	s6,0(sp)
    800019dc:	6121                	addi	sp,sp,64
    800019de:	8082                	ret

00000000800019e0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019e0:	1141                	addi	sp,sp,-16
    800019e2:	e422                	sd	s0,8(sp)
    800019e4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019e6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019e8:	2501                	sext.w	a0,a0
    800019ea:	6422                	ld	s0,8(sp)
    800019ec:	0141                	addi	sp,sp,16
    800019ee:	8082                	ret

00000000800019f0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019f0:	1141                	addi	sp,sp,-16
    800019f2:	e422                	sd	s0,8(sp)
    800019f4:	0800                	addi	s0,sp,16
    800019f6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019f8:	2781                	sext.w	a5,a5
    800019fa:	079e                	slli	a5,a5,0x7
  return c;
}
    800019fc:	00010517          	auipc	a0,0x10
    80001a00:	8d450513          	addi	a0,a0,-1836 # 800112d0 <cpus>
    80001a04:	953e                	add	a0,a0,a5
    80001a06:	6422                	ld	s0,8(sp)
    80001a08:	0141                	addi	sp,sp,16
    80001a0a:	8082                	ret

0000000080001a0c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a0c:	1101                	addi	sp,sp,-32
    80001a0e:	ec06                	sd	ra,24(sp)
    80001a10:	e822                	sd	s0,16(sp)
    80001a12:	e426                	sd	s1,8(sp)
    80001a14:	1000                	addi	s0,sp,32
  push_off();
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	16e080e7          	jalr	366(ra) # 80000b84 <push_off>
    80001a1e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a20:	2781                	sext.w	a5,a5
    80001a22:	079e                	slli	a5,a5,0x7
    80001a24:	00010717          	auipc	a4,0x10
    80001a28:	87c70713          	addi	a4,a4,-1924 # 800112a0 <pid_lock>
    80001a2c:	97ba                	add	a5,a5,a4
    80001a2e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	1f4080e7          	jalr	500(ra) # 80000c24 <pop_off>
  return p;
}
    80001a38:	8526                	mv	a0,s1
    80001a3a:	60e2                	ld	ra,24(sp)
    80001a3c:	6442                	ld	s0,16(sp)
    80001a3e:	64a2                	ld	s1,8(sp)
    80001a40:	6105                	addi	sp,sp,32
    80001a42:	8082                	ret

0000000080001a44 <syscall_count_print>:
void syscall_count_print(void){
    80001a44:	1141                	addi	sp,sp,-16
    80001a46:	e406                	sd	ra,8(sp)
    80001a48:	e022                	sd	s0,0(sp)
    80001a4a:	0800                	addi	s0,sp,16
	struct proc *p = myproc();
    80001a4c:	00000097          	auipc	ra,0x0
    80001a50:	fc0080e7          	jalr	-64(ra) # 80001a0c <myproc>
	printf("Number of system calls made by the current process: %d\n", syscallCount);
    80001a54:	16852583          	lw	a1,360(a0)
    80001a58:	00006517          	auipc	a0,0x6
    80001a5c:	7f050513          	addi	a0,a0,2032 # 80008248 <digits+0x208>
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	b24080e7          	jalr	-1244(ra) # 80000584 <printf>
}
    80001a68:	60a2                	ld	ra,8(sp)
    80001a6a:	6402                	ld	s0,0(sp)
    80001a6c:	0141                	addi	sp,sp,16
    80001a6e:	8082                	ret

0000000080001a70 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a70:	1141                	addi	sp,sp,-16
    80001a72:	e406                	sd	ra,8(sp)
    80001a74:	e022                	sd	s0,0(sp)
    80001a76:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	f94080e7          	jalr	-108(ra) # 80001a0c <myproc>
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	204080e7          	jalr	516(ra) # 80000c84 <release>

  if (first) {
    80001a88:	00007797          	auipc	a5,0x7
    80001a8c:	e287a783          	lw	a5,-472(a5) # 800088b0 <first.1>
    80001a90:	eb89                	bnez	a5,80001aa2 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a92:	00001097          	auipc	ra,0x1
    80001a96:	c18080e7          	jalr	-1000(ra) # 800026aa <usertrapret>
}
    80001a9a:	60a2                	ld	ra,8(sp)
    80001a9c:	6402                	ld	s0,0(sp)
    80001a9e:	0141                	addi	sp,sp,16
    80001aa0:	8082                	ret
    first = 0;
    80001aa2:	00007797          	auipc	a5,0x7
    80001aa6:	e007a723          	sw	zero,-498(a5) # 800088b0 <first.1>
    fsinit(ROOTDEV);
    80001aaa:	4505                	li	a0,1
    80001aac:	00002097          	auipc	ra,0x2
    80001ab0:	9b0080e7          	jalr	-1616(ra) # 8000345c <fsinit>
    80001ab4:	bff9                	j	80001a92 <forkret+0x22>

0000000080001ab6 <allocpid>:
allocpid() {
    80001ab6:	1101                	addi	sp,sp,-32
    80001ab8:	ec06                	sd	ra,24(sp)
    80001aba:	e822                	sd	s0,16(sp)
    80001abc:	e426                	sd	s1,8(sp)
    80001abe:	e04a                	sd	s2,0(sp)
    80001ac0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ac2:	0000f917          	auipc	s2,0xf
    80001ac6:	7de90913          	addi	s2,s2,2014 # 800112a0 <pid_lock>
    80001aca:	854a                	mv	a0,s2
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	104080e7          	jalr	260(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001ad4:	00007797          	auipc	a5,0x7
    80001ad8:	de078793          	addi	a5,a5,-544 # 800088b4 <nextpid>
    80001adc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ade:	0014871b          	addiw	a4,s1,1
    80001ae2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ae4:	854a                	mv	a0,s2
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	19e080e7          	jalr	414(ra) # 80000c84 <release>
}
    80001aee:	8526                	mv	a0,s1
    80001af0:	60e2                	ld	ra,24(sp)
    80001af2:	6442                	ld	s0,16(sp)
    80001af4:	64a2                	ld	s1,8(sp)
    80001af6:	6902                	ld	s2,0(sp)
    80001af8:	6105                	addi	sp,sp,32
    80001afa:	8082                	ret

0000000080001afc <proc_pagetable>:
{
    80001afc:	1101                	addi	sp,sp,-32
    80001afe:	ec06                	sd	ra,24(sp)
    80001b00:	e822                	sd	s0,16(sp)
    80001b02:	e426                	sd	s1,8(sp)
    80001b04:	e04a                	sd	s2,0(sp)
    80001b06:	1000                	addi	s0,sp,32
    80001b08:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b0a:	00000097          	auipc	ra,0x0
    80001b0e:	814080e7          	jalr	-2028(ra) # 8000131e <uvmcreate>
    80001b12:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b14:	c121                	beqz	a0,80001b54 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b16:	4729                	li	a4,10
    80001b18:	00005697          	auipc	a3,0x5
    80001b1c:	4e868693          	addi	a3,a3,1256 # 80007000 <_trampoline>
    80001b20:	6605                	lui	a2,0x1
    80001b22:	040005b7          	lui	a1,0x4000
    80001b26:	15fd                	addi	a1,a1,-1
    80001b28:	05b2                	slli	a1,a1,0xc
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	56a080e7          	jalr	1386(ra) # 80001094 <mappages>
    80001b32:	02054863          	bltz	a0,80001b62 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b36:	4719                	li	a4,6
    80001b38:	05893683          	ld	a3,88(s2)
    80001b3c:	6605                	lui	a2,0x1
    80001b3e:	020005b7          	lui	a1,0x2000
    80001b42:	15fd                	addi	a1,a1,-1
    80001b44:	05b6                	slli	a1,a1,0xd
    80001b46:	8526                	mv	a0,s1
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	54c080e7          	jalr	1356(ra) # 80001094 <mappages>
    80001b50:	02054163          	bltz	a0,80001b72 <proc_pagetable+0x76>
}
    80001b54:	8526                	mv	a0,s1
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret
    uvmfree(pagetable, 0);
    80001b62:	4581                	li	a1,0
    80001b64:	8526                	mv	a0,s1
    80001b66:	00000097          	auipc	ra,0x0
    80001b6a:	9b6080e7          	jalr	-1610(ra) # 8000151c <uvmfree>
    return 0;
    80001b6e:	4481                	li	s1,0
    80001b70:	b7d5                	j	80001b54 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b72:	4681                	li	a3,0
    80001b74:	4605                	li	a2,1
    80001b76:	040005b7          	lui	a1,0x4000
    80001b7a:	15fd                	addi	a1,a1,-1
    80001b7c:	05b2                	slli	a1,a1,0xc
    80001b7e:	8526                	mv	a0,s1
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	6da080e7          	jalr	1754(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b88:	4581                	li	a1,0
    80001b8a:	8526                	mv	a0,s1
    80001b8c:	00000097          	auipc	ra,0x0
    80001b90:	990080e7          	jalr	-1648(ra) # 8000151c <uvmfree>
    return 0;
    80001b94:	4481                	li	s1,0
    80001b96:	bf7d                	j	80001b54 <proc_pagetable+0x58>

0000000080001b98 <proc_freepagetable>:
{
    80001b98:	1101                	addi	sp,sp,-32
    80001b9a:	ec06                	sd	ra,24(sp)
    80001b9c:	e822                	sd	s0,16(sp)
    80001b9e:	e426                	sd	s1,8(sp)
    80001ba0:	e04a                	sd	s2,0(sp)
    80001ba2:	1000                	addi	s0,sp,32
    80001ba4:	84aa                	mv	s1,a0
    80001ba6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	040005b7          	lui	a1,0x4000
    80001bb0:	15fd                	addi	a1,a1,-1
    80001bb2:	05b2                	slli	a1,a1,0xc
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	6a6080e7          	jalr	1702(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bbc:	4681                	li	a3,0
    80001bbe:	4605                	li	a2,1
    80001bc0:	020005b7          	lui	a1,0x2000
    80001bc4:	15fd                	addi	a1,a1,-1
    80001bc6:	05b6                	slli	a1,a1,0xd
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	690080e7          	jalr	1680(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001bd2:	85ca                	mv	a1,s2
    80001bd4:	8526                	mv	a0,s1
    80001bd6:	00000097          	auipc	ra,0x0
    80001bda:	946080e7          	jalr	-1722(ra) # 8000151c <uvmfree>
}
    80001bde:	60e2                	ld	ra,24(sp)
    80001be0:	6442                	ld	s0,16(sp)
    80001be2:	64a2                	ld	s1,8(sp)
    80001be4:	6902                	ld	s2,0(sp)
    80001be6:	6105                	addi	sp,sp,32
    80001be8:	8082                	ret

0000000080001bea <freeproc>:
{
    80001bea:	1101                	addi	sp,sp,-32
    80001bec:	ec06                	sd	ra,24(sp)
    80001bee:	e822                	sd	s0,16(sp)
    80001bf0:	e426                	sd	s1,8(sp)
    80001bf2:	1000                	addi	s0,sp,32
    80001bf4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bf6:	6d28                	ld	a0,88(a0)
    80001bf8:	c509                	beqz	a0,80001c02 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	de8080e7          	jalr	-536(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001c02:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c06:	68a8                	ld	a0,80(s1)
    80001c08:	c511                	beqz	a0,80001c14 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c0a:	64ac                	ld	a1,72(s1)
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	f8c080e7          	jalr	-116(ra) # 80001b98 <proc_freepagetable>
  p->pagetable = 0;
    80001c14:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c18:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c1c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c20:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c24:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c28:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c2c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c30:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c34:	0004ac23          	sw	zero,24(s1)
}
    80001c38:	60e2                	ld	ra,24(sp)
    80001c3a:	6442                	ld	s0,16(sp)
    80001c3c:	64a2                	ld	s1,8(sp)
    80001c3e:	6105                	addi	sp,sp,32
    80001c40:	8082                	ret

0000000080001c42 <allocproc>:
{
    80001c42:	1101                	addi	sp,sp,-32
    80001c44:	ec06                	sd	ra,24(sp)
    80001c46:	e822                	sd	s0,16(sp)
    80001c48:	e426                	sd	s1,8(sp)
    80001c4a:	e04a                	sd	s2,0(sp)
    80001c4c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c4e:	00010497          	auipc	s1,0x10
    80001c52:	a8248493          	addi	s1,s1,-1406 # 800116d0 <proc>
    80001c56:	00015917          	auipc	s2,0x15
    80001c5a:	67a90913          	addi	s2,s2,1658 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	f70080e7          	jalr	-144(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001c68:	4c9c                	lw	a5,24(s1)
    80001c6a:	cf81                	beqz	a5,80001c82 <allocproc+0x40>
      release(&p->lock);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	016080e7          	jalr	22(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c76:	17048493          	addi	s1,s1,368
    80001c7a:	ff2492e3          	bne	s1,s2,80001c5e <allocproc+0x1c>
  return 0;
    80001c7e:	4481                	li	s1,0
    80001c80:	a899                	j	80001cd6 <allocproc+0x94>
  p->syscallCount = 0;
    80001c82:	1604b423          	sd	zero,360(s1)
  p->pid = allocpid();
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	e30080e7          	jalr	-464(ra) # 80001ab6 <allocpid>
    80001c8e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c90:	4785                	li	a5,1
    80001c92:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	e4c080e7          	jalr	-436(ra) # 80000ae0 <kalloc>
    80001c9c:	892a                	mv	s2,a0
    80001c9e:	eca8                	sd	a0,88(s1)
    80001ca0:	c131                	beqz	a0,80001ce4 <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	e58080e7          	jalr	-424(ra) # 80001afc <proc_pagetable>
    80001cac:	892a                	mv	s2,a0
    80001cae:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cb0:	c531                	beqz	a0,80001cfc <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001cb2:	07000613          	li	a2,112
    80001cb6:	4581                	li	a1,0
    80001cb8:	06048513          	addi	a0,s1,96
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	010080e7          	jalr	16(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001cc4:	00000797          	auipc	a5,0x0
    80001cc8:	dac78793          	addi	a5,a5,-596 # 80001a70 <forkret>
    80001ccc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cce:	60bc                	ld	a5,64(s1)
    80001cd0:	6705                	lui	a4,0x1
    80001cd2:	97ba                	add	a5,a5,a4
    80001cd4:	f4bc                	sd	a5,104(s1)
}
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	60e2                	ld	ra,24(sp)
    80001cda:	6442                	ld	s0,16(sp)
    80001cdc:	64a2                	ld	s1,8(sp)
    80001cde:	6902                	ld	s2,0(sp)
    80001ce0:	6105                	addi	sp,sp,32
    80001ce2:	8082                	ret
    freeproc(p);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	f04080e7          	jalr	-252(ra) # 80001bea <freeproc>
    release(&p->lock);
    80001cee:	8526                	mv	a0,s1
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	f94080e7          	jalr	-108(ra) # 80000c84 <release>
    return 0;
    80001cf8:	84ca                	mv	s1,s2
    80001cfa:	bff1                	j	80001cd6 <allocproc+0x94>
    freeproc(p);
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	eec080e7          	jalr	-276(ra) # 80001bea <freeproc>
    release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f7c080e7          	jalr	-132(ra) # 80000c84 <release>
    return 0;
    80001d10:	84ca                	mv	s1,s2
    80001d12:	b7d1                	j	80001cd6 <allocproc+0x94>

0000000080001d14 <userinit>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	f24080e7          	jalr	-220(ra) # 80001c42 <allocproc>
    80001d26:	84aa                	mv	s1,a0
  initproc = p;
    80001d28:	00007797          	auipc	a5,0x7
    80001d2c:	30a7b023          	sd	a0,768(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d30:	03400613          	li	a2,52
    80001d34:	00007597          	auipc	a1,0x7
    80001d38:	b8c58593          	addi	a1,a1,-1140 # 800088c0 <initcode>
    80001d3c:	6928                	ld	a0,80(a0)
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	60e080e7          	jalr	1550(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001d46:	6785                	lui	a5,0x1
    80001d48:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d4a:	6cb8                	ld	a4,88(s1)
    80001d4c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d50:	6cb8                	ld	a4,88(s1)
    80001d52:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d54:	4641                	li	a2,16
    80001d56:	00006597          	auipc	a1,0x6
    80001d5a:	52a58593          	addi	a1,a1,1322 # 80008280 <digits+0x240>
    80001d5e:	15848513          	addi	a0,s1,344
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	0b4080e7          	jalr	180(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d6a:	00006517          	auipc	a0,0x6
    80001d6e:	52650513          	addi	a0,a0,1318 # 80008290 <digits+0x250>
    80001d72:	00002097          	auipc	ra,0x2
    80001d76:	120080e7          	jalr	288(ra) # 80003e92 <namei>
    80001d7a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d7e:	478d                	li	a5,3
    80001d80:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d82:	8526                	mv	a0,s1
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	f00080e7          	jalr	-256(ra) # 80000c84 <release>
}
    80001d8c:	60e2                	ld	ra,24(sp)
    80001d8e:	6442                	ld	s0,16(sp)
    80001d90:	64a2                	ld	s1,8(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret

0000000080001d96 <growproc>:
{
    80001d96:	1101                	addi	sp,sp,-32
    80001d98:	ec06                	sd	ra,24(sp)
    80001d9a:	e822                	sd	s0,16(sp)
    80001d9c:	e426                	sd	s1,8(sp)
    80001d9e:	e04a                	sd	s2,0(sp)
    80001da0:	1000                	addi	s0,sp,32
    80001da2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	c68080e7          	jalr	-920(ra) # 80001a0c <myproc>
    80001dac:	892a                	mv	s2,a0
  sz = p->sz;
    80001dae:	652c                	ld	a1,72(a0)
    80001db0:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001db4:	00904f63          	bgtz	s1,80001dd2 <growproc+0x3c>
  } else if(n < 0){
    80001db8:	0204cd63          	bltz	s1,80001df2 <growproc+0x5c>
  p->sz = sz;
    80001dbc:	1782                	slli	a5,a5,0x20
    80001dbe:	9381                	srli	a5,a5,0x20
    80001dc0:	04f93423          	sd	a5,72(s2)
  return 0;
    80001dc4:	4501                	li	a0,0
}
    80001dc6:	60e2                	ld	ra,24(sp)
    80001dc8:	6442                	ld	s0,16(sp)
    80001dca:	64a2                	ld	s1,8(sp)
    80001dcc:	6902                	ld	s2,0(sp)
    80001dce:	6105                	addi	sp,sp,32
    80001dd0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dd2:	00f4863b          	addw	a2,s1,a5
    80001dd6:	1602                	slli	a2,a2,0x20
    80001dd8:	9201                	srli	a2,a2,0x20
    80001dda:	1582                	slli	a1,a1,0x20
    80001ddc:	9181                	srli	a1,a1,0x20
    80001dde:	6928                	ld	a0,80(a0)
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	626080e7          	jalr	1574(ra) # 80001406 <uvmalloc>
    80001de8:	0005079b          	sext.w	a5,a0
    80001dec:	fbe1                	bnez	a5,80001dbc <growproc+0x26>
      return -1;
    80001dee:	557d                	li	a0,-1
    80001df0:	bfd9                	j	80001dc6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df2:	00f4863b          	addw	a2,s1,a5
    80001df6:	1602                	slli	a2,a2,0x20
    80001df8:	9201                	srli	a2,a2,0x20
    80001dfa:	1582                	slli	a1,a1,0x20
    80001dfc:	9181                	srli	a1,a1,0x20
    80001dfe:	6928                	ld	a0,80(a0)
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	5be080e7          	jalr	1470(ra) # 800013be <uvmdealloc>
    80001e08:	0005079b          	sext.w	a5,a0
    80001e0c:	bf45                	j	80001dbc <growproc+0x26>

0000000080001e0e <fork>:
{
    80001e0e:	7139                	addi	sp,sp,-64
    80001e10:	fc06                	sd	ra,56(sp)
    80001e12:	f822                	sd	s0,48(sp)
    80001e14:	f426                	sd	s1,40(sp)
    80001e16:	f04a                	sd	s2,32(sp)
    80001e18:	ec4e                	sd	s3,24(sp)
    80001e1a:	e852                	sd	s4,16(sp)
    80001e1c:	e456                	sd	s5,8(sp)
    80001e1e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e20:	00000097          	auipc	ra,0x0
    80001e24:	bec080e7          	jalr	-1044(ra) # 80001a0c <myproc>
    80001e28:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e2a:	00000097          	auipc	ra,0x0
    80001e2e:	e18080e7          	jalr	-488(ra) # 80001c42 <allocproc>
    80001e32:	10050c63          	beqz	a0,80001f4a <fork+0x13c>
    80001e36:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e38:	048ab603          	ld	a2,72(s5)
    80001e3c:	692c                	ld	a1,80(a0)
    80001e3e:	050ab503          	ld	a0,80(s5)
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	714080e7          	jalr	1812(ra) # 80001556 <uvmcopy>
    80001e4a:	04054863          	bltz	a0,80001e9a <fork+0x8c>
  np->sz = p->sz;
    80001e4e:	048ab783          	ld	a5,72(s5)
    80001e52:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e56:	058ab683          	ld	a3,88(s5)
    80001e5a:	87b6                	mv	a5,a3
    80001e5c:	058a3703          	ld	a4,88(s4)
    80001e60:	12068693          	addi	a3,a3,288
    80001e64:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e68:	6788                	ld	a0,8(a5)
    80001e6a:	6b8c                	ld	a1,16(a5)
    80001e6c:	6f90                	ld	a2,24(a5)
    80001e6e:	01073023          	sd	a6,0(a4)
    80001e72:	e708                	sd	a0,8(a4)
    80001e74:	eb0c                	sd	a1,16(a4)
    80001e76:	ef10                	sd	a2,24(a4)
    80001e78:	02078793          	addi	a5,a5,32
    80001e7c:	02070713          	addi	a4,a4,32
    80001e80:	fed792e3          	bne	a5,a3,80001e64 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e84:	058a3783          	ld	a5,88(s4)
    80001e88:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e8c:	0d0a8493          	addi	s1,s5,208
    80001e90:	0d0a0913          	addi	s2,s4,208
    80001e94:	150a8993          	addi	s3,s5,336
    80001e98:	a00d                	j	80001eba <fork+0xac>
    freeproc(np);
    80001e9a:	8552                	mv	a0,s4
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	d4e080e7          	jalr	-690(ra) # 80001bea <freeproc>
    release(&np->lock);
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	dde080e7          	jalr	-546(ra) # 80000c84 <release>
    return -1;
    80001eae:	597d                	li	s2,-1
    80001eb0:	a059                	j	80001f36 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001eb2:	04a1                	addi	s1,s1,8
    80001eb4:	0921                	addi	s2,s2,8
    80001eb6:	01348b63          	beq	s1,s3,80001ecc <fork+0xbe>
    if(p->ofile[i])
    80001eba:	6088                	ld	a0,0(s1)
    80001ebc:	d97d                	beqz	a0,80001eb2 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ebe:	00002097          	auipc	ra,0x2
    80001ec2:	66a080e7          	jalr	1642(ra) # 80004528 <filedup>
    80001ec6:	00a93023          	sd	a0,0(s2)
    80001eca:	b7e5                	j	80001eb2 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ecc:	150ab503          	ld	a0,336(s5)
    80001ed0:	00001097          	auipc	ra,0x1
    80001ed4:	7c8080e7          	jalr	1992(ra) # 80003698 <idup>
    80001ed8:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001edc:	4641                	li	a2,16
    80001ede:	158a8593          	addi	a1,s5,344
    80001ee2:	158a0513          	addi	a0,s4,344
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	f30080e7          	jalr	-208(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001eee:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001ef2:	8552                	mv	a0,s4
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	d90080e7          	jalr	-624(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001efc:	0000f497          	auipc	s1,0xf
    80001f00:	3bc48493          	addi	s1,s1,956 # 800112b8 <wait_lock>
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	cca080e7          	jalr	-822(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001f0e:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f12:	8526                	mv	a0,s1
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	d70080e7          	jalr	-656(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001f1c:	8552                	mv	a0,s4
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	cb2080e7          	jalr	-846(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001f26:	478d                	li	a5,3
    80001f28:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f2c:	8552                	mv	a0,s4
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	d56080e7          	jalr	-682(ra) # 80000c84 <release>
}
    80001f36:	854a                	mv	a0,s2
    80001f38:	70e2                	ld	ra,56(sp)
    80001f3a:	7442                	ld	s0,48(sp)
    80001f3c:	74a2                	ld	s1,40(sp)
    80001f3e:	7902                	ld	s2,32(sp)
    80001f40:	69e2                	ld	s3,24(sp)
    80001f42:	6a42                	ld	s4,16(sp)
    80001f44:	6aa2                	ld	s5,8(sp)
    80001f46:	6121                	addi	sp,sp,64
    80001f48:	8082                	ret
    return -1;
    80001f4a:	597d                	li	s2,-1
    80001f4c:	b7ed                	j	80001f36 <fork+0x128>

0000000080001f4e <scheduler>:
{
    80001f4e:	7139                	addi	sp,sp,-64
    80001f50:	fc06                	sd	ra,56(sp)
    80001f52:	f822                	sd	s0,48(sp)
    80001f54:	f426                	sd	s1,40(sp)
    80001f56:	f04a                	sd	s2,32(sp)
    80001f58:	ec4e                	sd	s3,24(sp)
    80001f5a:	e852                	sd	s4,16(sp)
    80001f5c:	e456                	sd	s5,8(sp)
    80001f5e:	e05a                	sd	s6,0(sp)
    80001f60:	0080                	addi	s0,sp,64
    80001f62:	8792                	mv	a5,tp
  int id = r_tp();
    80001f64:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f66:	00779a93          	slli	s5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	33670713          	addi	a4,a4,822 # 800112a0 <pid_lock>
    80001f72:	9756                	add	a4,a4,s5
    80001f74:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f78:	0000f717          	auipc	a4,0xf
    80001f7c:	36070713          	addi	a4,a4,864 # 800112d8 <cpus+0x8>
    80001f80:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f82:	498d                	li	s3,3
        p->state = RUNNING;
    80001f84:	4b11                	li	s6,4
        c->proc = p;
    80001f86:	079e                	slli	a5,a5,0x7
    80001f88:	0000fa17          	auipc	s4,0xf
    80001f8c:	318a0a13          	addi	s4,s4,792 # 800112a0 <pid_lock>
    80001f90:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f92:	00015917          	auipc	s2,0x15
    80001f96:	33e90913          	addi	s2,s2,830 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f9e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fa2:	10079073          	csrw	sstatus,a5
    80001fa6:	0000f497          	auipc	s1,0xf
    80001faa:	72a48493          	addi	s1,s1,1834 # 800116d0 <proc>
    80001fae:	a811                	j	80001fc2 <scheduler+0x74>
      release(&p->lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	cd2080e7          	jalr	-814(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fba:	17048493          	addi	s1,s1,368
    80001fbe:	fd248ee3          	beq	s1,s2,80001f9a <scheduler+0x4c>
      acquire(&p->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	c0c080e7          	jalr	-1012(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001fcc:	4c9c                	lw	a5,24(s1)
    80001fce:	ff3791e3          	bne	a5,s3,80001fb0 <scheduler+0x62>
        p->state = RUNNING;
    80001fd2:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fd6:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fda:	06048593          	addi	a1,s1,96
    80001fde:	8556                	mv	a0,s5
    80001fe0:	00000097          	auipc	ra,0x0
    80001fe4:	620080e7          	jalr	1568(ra) # 80002600 <swtch>
        c->proc = 0;
    80001fe8:	020a3823          	sd	zero,48(s4)
    80001fec:	b7d1                	j	80001fb0 <scheduler+0x62>

0000000080001fee <sched>:
{
    80001fee:	7179                	addi	sp,sp,-48
    80001ff0:	f406                	sd	ra,40(sp)
    80001ff2:	f022                	sd	s0,32(sp)
    80001ff4:	ec26                	sd	s1,24(sp)
    80001ff6:	e84a                	sd	s2,16(sp)
    80001ff8:	e44e                	sd	s3,8(sp)
    80001ffa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ffc:	00000097          	auipc	ra,0x0
    80002000:	a10080e7          	jalr	-1520(ra) # 80001a0c <myproc>
    80002004:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	b50080e7          	jalr	-1200(ra) # 80000b56 <holding>
    8000200e:	c93d                	beqz	a0,80002084 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002010:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002012:	2781                	sext.w	a5,a5
    80002014:	079e                	slli	a5,a5,0x7
    80002016:	0000f717          	auipc	a4,0xf
    8000201a:	28a70713          	addi	a4,a4,650 # 800112a0 <pid_lock>
    8000201e:	97ba                	add	a5,a5,a4
    80002020:	0a87a703          	lw	a4,168(a5)
    80002024:	4785                	li	a5,1
    80002026:	06f71763          	bne	a4,a5,80002094 <sched+0xa6>
  if(p->state == RUNNING)
    8000202a:	4c98                	lw	a4,24(s1)
    8000202c:	4791                	li	a5,4
    8000202e:	06f70b63          	beq	a4,a5,800020a4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002032:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002036:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002038:	efb5                	bnez	a5,800020b4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000203a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000203c:	0000f917          	auipc	s2,0xf
    80002040:	26490913          	addi	s2,s2,612 # 800112a0 <pid_lock>
    80002044:	2781                	sext.w	a5,a5
    80002046:	079e                	slli	a5,a5,0x7
    80002048:	97ca                	add	a5,a5,s2
    8000204a:	0ac7a983          	lw	s3,172(a5)
    8000204e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002050:	2781                	sext.w	a5,a5
    80002052:	079e                	slli	a5,a5,0x7
    80002054:	0000f597          	auipc	a1,0xf
    80002058:	28458593          	addi	a1,a1,644 # 800112d8 <cpus+0x8>
    8000205c:	95be                	add	a1,a1,a5
    8000205e:	06048513          	addi	a0,s1,96
    80002062:	00000097          	auipc	ra,0x0
    80002066:	59e080e7          	jalr	1438(ra) # 80002600 <swtch>
    8000206a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000206c:	2781                	sext.w	a5,a5
    8000206e:	079e                	slli	a5,a5,0x7
    80002070:	993e                	add	s2,s2,a5
    80002072:	0b392623          	sw	s3,172(s2)
}
    80002076:	70a2                	ld	ra,40(sp)
    80002078:	7402                	ld	s0,32(sp)
    8000207a:	64e2                	ld	s1,24(sp)
    8000207c:	6942                	ld	s2,16(sp)
    8000207e:	69a2                	ld	s3,8(sp)
    80002080:	6145                	addi	sp,sp,48
    80002082:	8082                	ret
    panic("sched p->lock");
    80002084:	00006517          	auipc	a0,0x6
    80002088:	21450513          	addi	a0,a0,532 # 80008298 <digits+0x258>
    8000208c:	ffffe097          	auipc	ra,0xffffe
    80002090:	4ae080e7          	jalr	1198(ra) # 8000053a <panic>
    panic("sched locks");
    80002094:	00006517          	auipc	a0,0x6
    80002098:	21450513          	addi	a0,a0,532 # 800082a8 <digits+0x268>
    8000209c:	ffffe097          	auipc	ra,0xffffe
    800020a0:	49e080e7          	jalr	1182(ra) # 8000053a <panic>
    panic("sched running");
    800020a4:	00006517          	auipc	a0,0x6
    800020a8:	21450513          	addi	a0,a0,532 # 800082b8 <digits+0x278>
    800020ac:	ffffe097          	auipc	ra,0xffffe
    800020b0:	48e080e7          	jalr	1166(ra) # 8000053a <panic>
    panic("sched interruptible");
    800020b4:	00006517          	auipc	a0,0x6
    800020b8:	21450513          	addi	a0,a0,532 # 800082c8 <digits+0x288>
    800020bc:	ffffe097          	auipc	ra,0xffffe
    800020c0:	47e080e7          	jalr	1150(ra) # 8000053a <panic>

00000000800020c4 <yield>:
{
    800020c4:	1101                	addi	sp,sp,-32
    800020c6:	ec06                	sd	ra,24(sp)
    800020c8:	e822                	sd	s0,16(sp)
    800020ca:	e426                	sd	s1,8(sp)
    800020cc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	93e080e7          	jalr	-1730(ra) # 80001a0c <myproc>
    800020d6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	af8080e7          	jalr	-1288(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    800020e0:	478d                	li	a5,3
    800020e2:	cc9c                	sw	a5,24(s1)
  sched();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	f0a080e7          	jalr	-246(ra) # 80001fee <sched>
  release(&p->lock);
    800020ec:	8526                	mv	a0,s1
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	b96080e7          	jalr	-1130(ra) # 80000c84 <release>
}
    800020f6:	60e2                	ld	ra,24(sp)
    800020f8:	6442                	ld	s0,16(sp)
    800020fa:	64a2                	ld	s1,8(sp)
    800020fc:	6105                	addi	sp,sp,32
    800020fe:	8082                	ret

0000000080002100 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002100:	7179                	addi	sp,sp,-48
    80002102:	f406                	sd	ra,40(sp)
    80002104:	f022                	sd	s0,32(sp)
    80002106:	ec26                	sd	s1,24(sp)
    80002108:	e84a                	sd	s2,16(sp)
    8000210a:	e44e                	sd	s3,8(sp)
    8000210c:	1800                	addi	s0,sp,48
    8000210e:	89aa                	mv	s3,a0
    80002110:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002112:	00000097          	auipc	ra,0x0
    80002116:	8fa080e7          	jalr	-1798(ra) # 80001a0c <myproc>
    8000211a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	ab4080e7          	jalr	-1356(ra) # 80000bd0 <acquire>
  release(lk);
    80002124:	854a                	mv	a0,s2
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	b5e080e7          	jalr	-1186(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    8000212e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002132:	4789                	li	a5,2
    80002134:	cc9c                	sw	a5,24(s1)

  sched();
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	eb8080e7          	jalr	-328(ra) # 80001fee <sched>

  // Tidy up.
  p->chan = 0;
    8000213e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002142:	8526                	mv	a0,s1
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	b40080e7          	jalr	-1216(ra) # 80000c84 <release>
  acquire(lk);
    8000214c:	854a                	mv	a0,s2
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	a82080e7          	jalr	-1406(ra) # 80000bd0 <acquire>
}
    80002156:	70a2                	ld	ra,40(sp)
    80002158:	7402                	ld	s0,32(sp)
    8000215a:	64e2                	ld	s1,24(sp)
    8000215c:	6942                	ld	s2,16(sp)
    8000215e:	69a2                	ld	s3,8(sp)
    80002160:	6145                	addi	sp,sp,48
    80002162:	8082                	ret

0000000080002164 <wait>:
{
    80002164:	715d                	addi	sp,sp,-80
    80002166:	e486                	sd	ra,72(sp)
    80002168:	e0a2                	sd	s0,64(sp)
    8000216a:	fc26                	sd	s1,56(sp)
    8000216c:	f84a                	sd	s2,48(sp)
    8000216e:	f44e                	sd	s3,40(sp)
    80002170:	f052                	sd	s4,32(sp)
    80002172:	ec56                	sd	s5,24(sp)
    80002174:	e85a                	sd	s6,16(sp)
    80002176:	e45e                	sd	s7,8(sp)
    80002178:	e062                	sd	s8,0(sp)
    8000217a:	0880                	addi	s0,sp,80
    8000217c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	88e080e7          	jalr	-1906(ra) # 80001a0c <myproc>
    80002186:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002188:	0000f517          	auipc	a0,0xf
    8000218c:	13050513          	addi	a0,a0,304 # 800112b8 <wait_lock>
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	a40080e7          	jalr	-1472(ra) # 80000bd0 <acquire>
    havekids = 0;
    80002198:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000219a:	4a15                	li	s4,5
        havekids = 1;
    8000219c:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000219e:	00015997          	auipc	s3,0x15
    800021a2:	13298993          	addi	s3,s3,306 # 800172d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021a6:	0000fc17          	auipc	s8,0xf
    800021aa:	112c0c13          	addi	s8,s8,274 # 800112b8 <wait_lock>
    havekids = 0;
    800021ae:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800021b0:	0000f497          	auipc	s1,0xf
    800021b4:	52048493          	addi	s1,s1,1312 # 800116d0 <proc>
    800021b8:	a0bd                	j	80002226 <wait+0xc2>
          pid = np->pid;
    800021ba:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021be:	000b0e63          	beqz	s6,800021da <wait+0x76>
    800021c2:	4691                	li	a3,4
    800021c4:	02c48613          	addi	a2,s1,44
    800021c8:	85da                	mv	a1,s6
    800021ca:	05093503          	ld	a0,80(s2)
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	48c080e7          	jalr	1164(ra) # 8000165a <copyout>
    800021d6:	02054563          	bltz	a0,80002200 <wait+0x9c>
          freeproc(np);
    800021da:	8526                	mv	a0,s1
    800021dc:	00000097          	auipc	ra,0x0
    800021e0:	a0e080e7          	jalr	-1522(ra) # 80001bea <freeproc>
          release(&np->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	a9e080e7          	jalr	-1378(ra) # 80000c84 <release>
          release(&wait_lock);
    800021ee:	0000f517          	auipc	a0,0xf
    800021f2:	0ca50513          	addi	a0,a0,202 # 800112b8 <wait_lock>
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	a8e080e7          	jalr	-1394(ra) # 80000c84 <release>
          return pid;
    800021fe:	a09d                	j	80002264 <wait+0x100>
            release(&np->lock);
    80002200:	8526                	mv	a0,s1
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	a82080e7          	jalr	-1406(ra) # 80000c84 <release>
            release(&wait_lock);
    8000220a:	0000f517          	auipc	a0,0xf
    8000220e:	0ae50513          	addi	a0,a0,174 # 800112b8 <wait_lock>
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a72080e7          	jalr	-1422(ra) # 80000c84 <release>
            return -1;
    8000221a:	59fd                	li	s3,-1
    8000221c:	a0a1                	j	80002264 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000221e:	17048493          	addi	s1,s1,368
    80002222:	03348463          	beq	s1,s3,8000224a <wait+0xe6>
      if(np->parent == p){
    80002226:	7c9c                	ld	a5,56(s1)
    80002228:	ff279be3          	bne	a5,s2,8000221e <wait+0xba>
        acquire(&np->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	9a2080e7          	jalr	-1630(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002236:	4c9c                	lw	a5,24(s1)
    80002238:	f94781e3          	beq	a5,s4,800021ba <wait+0x56>
        release(&np->lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        havekids = 1;
    80002246:	8756                	mv	a4,s5
    80002248:	bfd9                	j	8000221e <wait+0xba>
    if(!havekids || p->killed){
    8000224a:	c701                	beqz	a4,80002252 <wait+0xee>
    8000224c:	02892783          	lw	a5,40(s2)
    80002250:	c79d                	beqz	a5,8000227e <wait+0x11a>
      release(&wait_lock);
    80002252:	0000f517          	auipc	a0,0xf
    80002256:	06650513          	addi	a0,a0,102 # 800112b8 <wait_lock>
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	a2a080e7          	jalr	-1494(ra) # 80000c84 <release>
      return -1;
    80002262:	59fd                	li	s3,-1
}
    80002264:	854e                	mv	a0,s3
    80002266:	60a6                	ld	ra,72(sp)
    80002268:	6406                	ld	s0,64(sp)
    8000226a:	74e2                	ld	s1,56(sp)
    8000226c:	7942                	ld	s2,48(sp)
    8000226e:	79a2                	ld	s3,40(sp)
    80002270:	7a02                	ld	s4,32(sp)
    80002272:	6ae2                	ld	s5,24(sp)
    80002274:	6b42                	ld	s6,16(sp)
    80002276:	6ba2                	ld	s7,8(sp)
    80002278:	6c02                	ld	s8,0(sp)
    8000227a:	6161                	addi	sp,sp,80
    8000227c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000227e:	85e2                	mv	a1,s8
    80002280:	854a                	mv	a0,s2
    80002282:	00000097          	auipc	ra,0x0
    80002286:	e7e080e7          	jalr	-386(ra) # 80002100 <sleep>
    havekids = 0;
    8000228a:	b715                	j	800021ae <wait+0x4a>

000000008000228c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000228c:	7139                	addi	sp,sp,-64
    8000228e:	fc06                	sd	ra,56(sp)
    80002290:	f822                	sd	s0,48(sp)
    80002292:	f426                	sd	s1,40(sp)
    80002294:	f04a                	sd	s2,32(sp)
    80002296:	ec4e                	sd	s3,24(sp)
    80002298:	e852                	sd	s4,16(sp)
    8000229a:	e456                	sd	s5,8(sp)
    8000229c:	0080                	addi	s0,sp,64
    8000229e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022a0:	0000f497          	auipc	s1,0xf
    800022a4:	43048493          	addi	s1,s1,1072 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022a8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022aa:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022ac:	00015917          	auipc	s2,0x15
    800022b0:	02490913          	addi	s2,s2,36 # 800172d0 <tickslock>
    800022b4:	a811                	j	800022c8 <wakeup+0x3c>
      }
      release(&p->lock);
    800022b6:	8526                	mv	a0,s1
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	9cc080e7          	jalr	-1588(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022c0:	17048493          	addi	s1,s1,368
    800022c4:	03248663          	beq	s1,s2,800022f0 <wakeup+0x64>
    if(p != myproc()){
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	744080e7          	jalr	1860(ra) # 80001a0c <myproc>
    800022d0:	fea488e3          	beq	s1,a0,800022c0 <wakeup+0x34>
      acquire(&p->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	8fa080e7          	jalr	-1798(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022de:	4c9c                	lw	a5,24(s1)
    800022e0:	fd379be3          	bne	a5,s3,800022b6 <wakeup+0x2a>
    800022e4:	709c                	ld	a5,32(s1)
    800022e6:	fd4798e3          	bne	a5,s4,800022b6 <wakeup+0x2a>
        p->state = RUNNABLE;
    800022ea:	0154ac23          	sw	s5,24(s1)
    800022ee:	b7e1                	j	800022b6 <wakeup+0x2a>
    }
  }
}
    800022f0:	70e2                	ld	ra,56(sp)
    800022f2:	7442                	ld	s0,48(sp)
    800022f4:	74a2                	ld	s1,40(sp)
    800022f6:	7902                	ld	s2,32(sp)
    800022f8:	69e2                	ld	s3,24(sp)
    800022fa:	6a42                	ld	s4,16(sp)
    800022fc:	6aa2                	ld	s5,8(sp)
    800022fe:	6121                	addi	sp,sp,64
    80002300:	8082                	ret

0000000080002302 <reparent>:
{
    80002302:	7179                	addi	sp,sp,-48
    80002304:	f406                	sd	ra,40(sp)
    80002306:	f022                	sd	s0,32(sp)
    80002308:	ec26                	sd	s1,24(sp)
    8000230a:	e84a                	sd	s2,16(sp)
    8000230c:	e44e                	sd	s3,8(sp)
    8000230e:	e052                	sd	s4,0(sp)
    80002310:	1800                	addi	s0,sp,48
    80002312:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002314:	0000f497          	auipc	s1,0xf
    80002318:	3bc48493          	addi	s1,s1,956 # 800116d0 <proc>
      pp->parent = initproc;
    8000231c:	00007a17          	auipc	s4,0x7
    80002320:	d0ca0a13          	addi	s4,s4,-756 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002324:	00015997          	auipc	s3,0x15
    80002328:	fac98993          	addi	s3,s3,-84 # 800172d0 <tickslock>
    8000232c:	a029                	j	80002336 <reparent+0x34>
    8000232e:	17048493          	addi	s1,s1,368
    80002332:	01348d63          	beq	s1,s3,8000234c <reparent+0x4a>
    if(pp->parent == p){
    80002336:	7c9c                	ld	a5,56(s1)
    80002338:	ff279be3          	bne	a5,s2,8000232e <reparent+0x2c>
      pp->parent = initproc;
    8000233c:	000a3503          	ld	a0,0(s4)
    80002340:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002342:	00000097          	auipc	ra,0x0
    80002346:	f4a080e7          	jalr	-182(ra) # 8000228c <wakeup>
    8000234a:	b7d5                	j	8000232e <reparent+0x2c>
}
    8000234c:	70a2                	ld	ra,40(sp)
    8000234e:	7402                	ld	s0,32(sp)
    80002350:	64e2                	ld	s1,24(sp)
    80002352:	6942                	ld	s2,16(sp)
    80002354:	69a2                	ld	s3,8(sp)
    80002356:	6a02                	ld	s4,0(sp)
    80002358:	6145                	addi	sp,sp,48
    8000235a:	8082                	ret

000000008000235c <exit>:
{
    8000235c:	7179                	addi	sp,sp,-48
    8000235e:	f406                	sd	ra,40(sp)
    80002360:	f022                	sd	s0,32(sp)
    80002362:	ec26                	sd	s1,24(sp)
    80002364:	e84a                	sd	s2,16(sp)
    80002366:	e44e                	sd	s3,8(sp)
    80002368:	e052                	sd	s4,0(sp)
    8000236a:	1800                	addi	s0,sp,48
    8000236c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	69e080e7          	jalr	1694(ra) # 80001a0c <myproc>
    80002376:	89aa                	mv	s3,a0
  if(p == initproc)
    80002378:	00007797          	auipc	a5,0x7
    8000237c:	cb07b783          	ld	a5,-848(a5) # 80009028 <initproc>
    80002380:	0d050493          	addi	s1,a0,208
    80002384:	15050913          	addi	s2,a0,336
    80002388:	02a79363          	bne	a5,a0,800023ae <exit+0x52>
    panic("init exiting");
    8000238c:	00006517          	auipc	a0,0x6
    80002390:	f5450513          	addi	a0,a0,-172 # 800082e0 <digits+0x2a0>
    80002394:	ffffe097          	auipc	ra,0xffffe
    80002398:	1a6080e7          	jalr	422(ra) # 8000053a <panic>
      fileclose(f);
    8000239c:	00002097          	auipc	ra,0x2
    800023a0:	1de080e7          	jalr	478(ra) # 8000457a <fileclose>
      p->ofile[fd] = 0;
    800023a4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023a8:	04a1                	addi	s1,s1,8
    800023aa:	01248563          	beq	s1,s2,800023b4 <exit+0x58>
    if(p->ofile[fd]){
    800023ae:	6088                	ld	a0,0(s1)
    800023b0:	f575                	bnez	a0,8000239c <exit+0x40>
    800023b2:	bfdd                	j	800023a8 <exit+0x4c>
  begin_op();
    800023b4:	00002097          	auipc	ra,0x2
    800023b8:	cfe080e7          	jalr	-770(ra) # 800040b2 <begin_op>
  iput(p->cwd);
    800023bc:	1509b503          	ld	a0,336(s3)
    800023c0:	00001097          	auipc	ra,0x1
    800023c4:	4d0080e7          	jalr	1232(ra) # 80003890 <iput>
  end_op();
    800023c8:	00002097          	auipc	ra,0x2
    800023cc:	d68080e7          	jalr	-664(ra) # 80004130 <end_op>
  p->cwd = 0;
    800023d0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023d4:	0000f497          	auipc	s1,0xf
    800023d8:	ee448493          	addi	s1,s1,-284 # 800112b8 <wait_lock>
    800023dc:	8526                	mv	a0,s1
    800023de:	ffffe097          	auipc	ra,0xffffe
    800023e2:	7f2080e7          	jalr	2034(ra) # 80000bd0 <acquire>
  reparent(p);
    800023e6:	854e                	mv	a0,s3
    800023e8:	00000097          	auipc	ra,0x0
    800023ec:	f1a080e7          	jalr	-230(ra) # 80002302 <reparent>
  wakeup(p->parent);
    800023f0:	0389b503          	ld	a0,56(s3)
    800023f4:	00000097          	auipc	ra,0x0
    800023f8:	e98080e7          	jalr	-360(ra) # 8000228c <wakeup>
  acquire(&p->lock);
    800023fc:	854e                	mv	a0,s3
    800023fe:	ffffe097          	auipc	ra,0xffffe
    80002402:	7d2080e7          	jalr	2002(ra) # 80000bd0 <acquire>
  p->xstate = status;
    80002406:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000240a:	4795                	li	a5,5
    8000240c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002410:	8526                	mv	a0,s1
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	872080e7          	jalr	-1934(ra) # 80000c84 <release>
  sched();
    8000241a:	00000097          	auipc	ra,0x0
    8000241e:	bd4080e7          	jalr	-1068(ra) # 80001fee <sched>
  panic("zombie exit");
    80002422:	00006517          	auipc	a0,0x6
    80002426:	ece50513          	addi	a0,a0,-306 # 800082f0 <digits+0x2b0>
    8000242a:	ffffe097          	auipc	ra,0xffffe
    8000242e:	110080e7          	jalr	272(ra) # 8000053a <panic>

0000000080002432 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002432:	7179                	addi	sp,sp,-48
    80002434:	f406                	sd	ra,40(sp)
    80002436:	f022                	sd	s0,32(sp)
    80002438:	ec26                	sd	s1,24(sp)
    8000243a:	e84a                	sd	s2,16(sp)
    8000243c:	e44e                	sd	s3,8(sp)
    8000243e:	1800                	addi	s0,sp,48
    80002440:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002442:	0000f497          	auipc	s1,0xf
    80002446:	28e48493          	addi	s1,s1,654 # 800116d0 <proc>
    8000244a:	00015997          	auipc	s3,0x15
    8000244e:	e8698993          	addi	s3,s3,-378 # 800172d0 <tickslock>
    acquire(&p->lock);
    80002452:	8526                	mv	a0,s1
    80002454:	ffffe097          	auipc	ra,0xffffe
    80002458:	77c080e7          	jalr	1916(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    8000245c:	589c                	lw	a5,48(s1)
    8000245e:	01278d63          	beq	a5,s2,80002478 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002462:	8526                	mv	a0,s1
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	820080e7          	jalr	-2016(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000246c:	17048493          	addi	s1,s1,368
    80002470:	ff3491e3          	bne	s1,s3,80002452 <kill+0x20>
  }
  return -1;
    80002474:	557d                	li	a0,-1
    80002476:	a829                	j	80002490 <kill+0x5e>
      p->killed = 1;
    80002478:	4785                	li	a5,1
    8000247a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000247c:	4c98                	lw	a4,24(s1)
    8000247e:	4789                	li	a5,2
    80002480:	00f70f63          	beq	a4,a5,8000249e <kill+0x6c>
      release(&p->lock);
    80002484:	8526                	mv	a0,s1
    80002486:	ffffe097          	auipc	ra,0xffffe
    8000248a:	7fe080e7          	jalr	2046(ra) # 80000c84 <release>
      return 0;
    8000248e:	4501                	li	a0,0
}
    80002490:	70a2                	ld	ra,40(sp)
    80002492:	7402                	ld	s0,32(sp)
    80002494:	64e2                	ld	s1,24(sp)
    80002496:	6942                	ld	s2,16(sp)
    80002498:	69a2                	ld	s3,8(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
        p->state = RUNNABLE;
    8000249e:	478d                	li	a5,3
    800024a0:	cc9c                	sw	a5,24(s1)
    800024a2:	b7cd                	j	80002484 <kill+0x52>

00000000800024a4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024a4:	7179                	addi	sp,sp,-48
    800024a6:	f406                	sd	ra,40(sp)
    800024a8:	f022                	sd	s0,32(sp)
    800024aa:	ec26                	sd	s1,24(sp)
    800024ac:	e84a                	sd	s2,16(sp)
    800024ae:	e44e                	sd	s3,8(sp)
    800024b0:	e052                	sd	s4,0(sp)
    800024b2:	1800                	addi	s0,sp,48
    800024b4:	84aa                	mv	s1,a0
    800024b6:	892e                	mv	s2,a1
    800024b8:	89b2                	mv	s3,a2
    800024ba:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	550080e7          	jalr	1360(ra) # 80001a0c <myproc>
  if(user_dst){
    800024c4:	c08d                	beqz	s1,800024e6 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024c6:	86d2                	mv	a3,s4
    800024c8:	864e                	mv	a2,s3
    800024ca:	85ca                	mv	a1,s2
    800024cc:	6928                	ld	a0,80(a0)
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	18c080e7          	jalr	396(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024d6:	70a2                	ld	ra,40(sp)
    800024d8:	7402                	ld	s0,32(sp)
    800024da:	64e2                	ld	s1,24(sp)
    800024dc:	6942                	ld	s2,16(sp)
    800024de:	69a2                	ld	s3,8(sp)
    800024e0:	6a02                	ld	s4,0(sp)
    800024e2:	6145                	addi	sp,sp,48
    800024e4:	8082                	ret
    memmove((char *)dst, src, len);
    800024e6:	000a061b          	sext.w	a2,s4
    800024ea:	85ce                	mv	a1,s3
    800024ec:	854a                	mv	a0,s2
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	83a080e7          	jalr	-1990(ra) # 80000d28 <memmove>
    return 0;
    800024f6:	8526                	mv	a0,s1
    800024f8:	bff9                	j	800024d6 <either_copyout+0x32>

00000000800024fa <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024fa:	7179                	addi	sp,sp,-48
    800024fc:	f406                	sd	ra,40(sp)
    800024fe:	f022                	sd	s0,32(sp)
    80002500:	ec26                	sd	s1,24(sp)
    80002502:	e84a                	sd	s2,16(sp)
    80002504:	e44e                	sd	s3,8(sp)
    80002506:	e052                	sd	s4,0(sp)
    80002508:	1800                	addi	s0,sp,48
    8000250a:	892a                	mv	s2,a0
    8000250c:	84ae                	mv	s1,a1
    8000250e:	89b2                	mv	s3,a2
    80002510:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	4fa080e7          	jalr	1274(ra) # 80001a0c <myproc>
  if(user_src){
    8000251a:	c08d                	beqz	s1,8000253c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000251c:	86d2                	mv	a3,s4
    8000251e:	864e                	mv	a2,s3
    80002520:	85ca                	mv	a1,s2
    80002522:	6928                	ld	a0,80(a0)
    80002524:	fffff097          	auipc	ra,0xfffff
    80002528:	1c2080e7          	jalr	450(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000252c:	70a2                	ld	ra,40(sp)
    8000252e:	7402                	ld	s0,32(sp)
    80002530:	64e2                	ld	s1,24(sp)
    80002532:	6942                	ld	s2,16(sp)
    80002534:	69a2                	ld	s3,8(sp)
    80002536:	6a02                	ld	s4,0(sp)
    80002538:	6145                	addi	sp,sp,48
    8000253a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000253c:	000a061b          	sext.w	a2,s4
    80002540:	85ce                	mv	a1,s3
    80002542:	854a                	mv	a0,s2
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	7e4080e7          	jalr	2020(ra) # 80000d28 <memmove>
    return 0;
    8000254c:	8526                	mv	a0,s1
    8000254e:	bff9                	j	8000252c <either_copyin+0x32>

0000000080002550 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002550:	715d                	addi	sp,sp,-80
    80002552:	e486                	sd	ra,72(sp)
    80002554:	e0a2                	sd	s0,64(sp)
    80002556:	fc26                	sd	s1,56(sp)
    80002558:	f84a                	sd	s2,48(sp)
    8000255a:	f44e                	sd	s3,40(sp)
    8000255c:	f052                	sd	s4,32(sp)
    8000255e:	ec56                	sd	s5,24(sp)
    80002560:	e85a                	sd	s6,16(sp)
    80002562:	e45e                	sd	s7,8(sp)
    80002564:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002566:	00006517          	auipc	a0,0x6
    8000256a:	b6250513          	addi	a0,a0,-1182 # 800080c8 <digits+0x88>
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	016080e7          	jalr	22(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002576:	0000f497          	auipc	s1,0xf
    8000257a:	2b248493          	addi	s1,s1,690 # 80011828 <proc+0x158>
    8000257e:	00015917          	auipc	s2,0x15
    80002582:	eaa90913          	addi	s2,s2,-342 # 80017428 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002586:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002588:	00006997          	auipc	s3,0x6
    8000258c:	d7898993          	addi	s3,s3,-648 # 80008300 <digits+0x2c0>
    printf("%d %s %s", p->pid, state, p->name);
    80002590:	00006a97          	auipc	s5,0x6
    80002594:	d78a8a93          	addi	s5,s5,-648 # 80008308 <digits+0x2c8>
    printf("\n");
    80002598:	00006a17          	auipc	s4,0x6
    8000259c:	b30a0a13          	addi	s4,s4,-1232 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a0:	00006b97          	auipc	s7,0x6
    800025a4:	da0b8b93          	addi	s7,s7,-608 # 80008340 <states.0>
    800025a8:	a00d                	j	800025ca <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025aa:	ed86a583          	lw	a1,-296(a3)
    800025ae:	8556                	mv	a0,s5
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	fd4080e7          	jalr	-44(ra) # 80000584 <printf>
    printf("\n");
    800025b8:	8552                	mv	a0,s4
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	fca080e7          	jalr	-54(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c2:	17048493          	addi	s1,s1,368
    800025c6:	03248263          	beq	s1,s2,800025ea <procdump+0x9a>
    if(p->state == UNUSED)
    800025ca:	86a6                	mv	a3,s1
    800025cc:	ec04a783          	lw	a5,-320(s1)
    800025d0:	dbed                	beqz	a5,800025c2 <procdump+0x72>
      state = "???";
    800025d2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d4:	fcfb6be3          	bltu	s6,a5,800025aa <procdump+0x5a>
    800025d8:	02079713          	slli	a4,a5,0x20
    800025dc:	01d75793          	srli	a5,a4,0x1d
    800025e0:	97de                	add	a5,a5,s7
    800025e2:	6390                	ld	a2,0(a5)
    800025e4:	f279                	bnez	a2,800025aa <procdump+0x5a>
      state = "???";
    800025e6:	864e                	mv	a2,s3
    800025e8:	b7c9                	j	800025aa <procdump+0x5a>
  }
}
    800025ea:	60a6                	ld	ra,72(sp)
    800025ec:	6406                	ld	s0,64(sp)
    800025ee:	74e2                	ld	s1,56(sp)
    800025f0:	7942                	ld	s2,48(sp)
    800025f2:	79a2                	ld	s3,40(sp)
    800025f4:	7a02                	ld	s4,32(sp)
    800025f6:	6ae2                	ld	s5,24(sp)
    800025f8:	6b42                	ld	s6,16(sp)
    800025fa:	6ba2                	ld	s7,8(sp)
    800025fc:	6161                	addi	sp,sp,80
    800025fe:	8082                	ret

0000000080002600 <swtch>:
    80002600:	00153023          	sd	ra,0(a0)
    80002604:	00253423          	sd	sp,8(a0)
    80002608:	e900                	sd	s0,16(a0)
    8000260a:	ed04                	sd	s1,24(a0)
    8000260c:	03253023          	sd	s2,32(a0)
    80002610:	03353423          	sd	s3,40(a0)
    80002614:	03453823          	sd	s4,48(a0)
    80002618:	03553c23          	sd	s5,56(a0)
    8000261c:	05653023          	sd	s6,64(a0)
    80002620:	05753423          	sd	s7,72(a0)
    80002624:	05853823          	sd	s8,80(a0)
    80002628:	05953c23          	sd	s9,88(a0)
    8000262c:	07a53023          	sd	s10,96(a0)
    80002630:	07b53423          	sd	s11,104(a0)
    80002634:	0005b083          	ld	ra,0(a1)
    80002638:	0085b103          	ld	sp,8(a1)
    8000263c:	6980                	ld	s0,16(a1)
    8000263e:	6d84                	ld	s1,24(a1)
    80002640:	0205b903          	ld	s2,32(a1)
    80002644:	0285b983          	ld	s3,40(a1)
    80002648:	0305ba03          	ld	s4,48(a1)
    8000264c:	0385ba83          	ld	s5,56(a1)
    80002650:	0405bb03          	ld	s6,64(a1)
    80002654:	0485bb83          	ld	s7,72(a1)
    80002658:	0505bc03          	ld	s8,80(a1)
    8000265c:	0585bc83          	ld	s9,88(a1)
    80002660:	0605bd03          	ld	s10,96(a1)
    80002664:	0685bd83          	ld	s11,104(a1)
    80002668:	8082                	ret

000000008000266a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000266a:	1141                	addi	sp,sp,-16
    8000266c:	e406                	sd	ra,8(sp)
    8000266e:	e022                	sd	s0,0(sp)
    80002670:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002672:	00006597          	auipc	a1,0x6
    80002676:	cfe58593          	addi	a1,a1,-770 # 80008370 <states.0+0x30>
    8000267a:	00015517          	auipc	a0,0x15
    8000267e:	c5650513          	addi	a0,a0,-938 # 800172d0 <tickslock>
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	4be080e7          	jalr	1214(ra) # 80000b40 <initlock>
}
    8000268a:	60a2                	ld	ra,8(sp)
    8000268c:	6402                	ld	s0,0(sp)
    8000268e:	0141                	addi	sp,sp,16
    80002690:	8082                	ret

0000000080002692 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002692:	1141                	addi	sp,sp,-16
    80002694:	e422                	sd	s0,8(sp)
    80002696:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002698:	00003797          	auipc	a5,0x3
    8000269c:	51878793          	addi	a5,a5,1304 # 80005bb0 <kernelvec>
    800026a0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026a4:	6422                	ld	s0,8(sp)
    800026a6:	0141                	addi	sp,sp,16
    800026a8:	8082                	ret

00000000800026aa <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026aa:	1141                	addi	sp,sp,-16
    800026ac:	e406                	sd	ra,8(sp)
    800026ae:	e022                	sd	s0,0(sp)
    800026b0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026b2:	fffff097          	auipc	ra,0xfffff
    800026b6:	35a080e7          	jalr	858(ra) # 80001a0c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026be:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026c4:	00005697          	auipc	a3,0x5
    800026c8:	93c68693          	addi	a3,a3,-1732 # 80007000 <_trampoline>
    800026cc:	00005717          	auipc	a4,0x5
    800026d0:	93470713          	addi	a4,a4,-1740 # 80007000 <_trampoline>
    800026d4:	8f15                	sub	a4,a4,a3
    800026d6:	040007b7          	lui	a5,0x4000
    800026da:	17fd                	addi	a5,a5,-1
    800026dc:	07b2                	slli	a5,a5,0xc
    800026de:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e0:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026e4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026e6:	18002673          	csrr	a2,satp
    800026ea:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026ec:	6d30                	ld	a2,88(a0)
    800026ee:	6138                	ld	a4,64(a0)
    800026f0:	6585                	lui	a1,0x1
    800026f2:	972e                	add	a4,a4,a1
    800026f4:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026f6:	6d38                	ld	a4,88(a0)
    800026f8:	00000617          	auipc	a2,0x0
    800026fc:	13860613          	addi	a2,a2,312 # 80002830 <usertrap>
    80002700:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002702:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002704:	8612                	mv	a2,tp
    80002706:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002708:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000270c:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002710:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002714:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002718:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000271a:	6f18                	ld	a4,24(a4)
    8000271c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002720:	692c                	ld	a1,80(a0)
    80002722:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002724:	00005717          	auipc	a4,0x5
    80002728:	96c70713          	addi	a4,a4,-1684 # 80007090 <userret>
    8000272c:	8f15                	sub	a4,a4,a3
    8000272e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002730:	577d                	li	a4,-1
    80002732:	177e                	slli	a4,a4,0x3f
    80002734:	8dd9                	or	a1,a1,a4
    80002736:	02000537          	lui	a0,0x2000
    8000273a:	157d                	addi	a0,a0,-1
    8000273c:	0536                	slli	a0,a0,0xd
    8000273e:	9782                	jalr	a5
}
    80002740:	60a2                	ld	ra,8(sp)
    80002742:	6402                	ld	s0,0(sp)
    80002744:	0141                	addi	sp,sp,16
    80002746:	8082                	ret

0000000080002748 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002748:	1101                	addi	sp,sp,-32
    8000274a:	ec06                	sd	ra,24(sp)
    8000274c:	e822                	sd	s0,16(sp)
    8000274e:	e426                	sd	s1,8(sp)
    80002750:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002752:	00015497          	auipc	s1,0x15
    80002756:	b7e48493          	addi	s1,s1,-1154 # 800172d0 <tickslock>
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	474080e7          	jalr	1140(ra) # 80000bd0 <acquire>
  ticks++;
    80002764:	00007517          	auipc	a0,0x7
    80002768:	8cc50513          	addi	a0,a0,-1844 # 80009030 <ticks>
    8000276c:	411c                	lw	a5,0(a0)
    8000276e:	2785                	addiw	a5,a5,1
    80002770:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002772:	00000097          	auipc	ra,0x0
    80002776:	b1a080e7          	jalr	-1254(ra) # 8000228c <wakeup>
  release(&tickslock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	508080e7          	jalr	1288(ra) # 80000c84 <release>
}
    80002784:	60e2                	ld	ra,24(sp)
    80002786:	6442                	ld	s0,16(sp)
    80002788:	64a2                	ld	s1,8(sp)
    8000278a:	6105                	addi	sp,sp,32
    8000278c:	8082                	ret

000000008000278e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000278e:	1101                	addi	sp,sp,-32
    80002790:	ec06                	sd	ra,24(sp)
    80002792:	e822                	sd	s0,16(sp)
    80002794:	e426                	sd	s1,8(sp)
    80002796:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002798:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000279c:	00074d63          	bltz	a4,800027b6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027a0:	57fd                	li	a5,-1
    800027a2:	17fe                	slli	a5,a5,0x3f
    800027a4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027a6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027a8:	06f70363          	beq	a4,a5,8000280e <devintr+0x80>
  }
}
    800027ac:	60e2                	ld	ra,24(sp)
    800027ae:	6442                	ld	s0,16(sp)
    800027b0:	64a2                	ld	s1,8(sp)
    800027b2:	6105                	addi	sp,sp,32
    800027b4:	8082                	ret
     (scause & 0xff) == 9){
    800027b6:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800027ba:	46a5                	li	a3,9
    800027bc:	fed792e3          	bne	a5,a3,800027a0 <devintr+0x12>
    int irq = plic_claim();
    800027c0:	00003097          	auipc	ra,0x3
    800027c4:	4f8080e7          	jalr	1272(ra) # 80005cb8 <plic_claim>
    800027c8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027ca:	47a9                	li	a5,10
    800027cc:	02f50763          	beq	a0,a5,800027fa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027d0:	4785                	li	a5,1
    800027d2:	02f50963          	beq	a0,a5,80002804 <devintr+0x76>
    return 1;
    800027d6:	4505                	li	a0,1
    } else if(irq){
    800027d8:	d8f1                	beqz	s1,800027ac <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027da:	85a6                	mv	a1,s1
    800027dc:	00006517          	auipc	a0,0x6
    800027e0:	b9c50513          	addi	a0,a0,-1124 # 80008378 <states.0+0x38>
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	da0080e7          	jalr	-608(ra) # 80000584 <printf>
      plic_complete(irq);
    800027ec:	8526                	mv	a0,s1
    800027ee:	00003097          	auipc	ra,0x3
    800027f2:	4ee080e7          	jalr	1262(ra) # 80005cdc <plic_complete>
    return 1;
    800027f6:	4505                	li	a0,1
    800027f8:	bf55                	j	800027ac <devintr+0x1e>
      uartintr();
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	198080e7          	jalr	408(ra) # 80000992 <uartintr>
    80002802:	b7ed                	j	800027ec <devintr+0x5e>
      virtio_disk_intr();
    80002804:	00004097          	auipc	ra,0x4
    80002808:	964080e7          	jalr	-1692(ra) # 80006168 <virtio_disk_intr>
    8000280c:	b7c5                	j	800027ec <devintr+0x5e>
    if(cpuid() == 0){
    8000280e:	fffff097          	auipc	ra,0xfffff
    80002812:	1d2080e7          	jalr	466(ra) # 800019e0 <cpuid>
    80002816:	c901                	beqz	a0,80002826 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002818:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000281c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000281e:	14479073          	csrw	sip,a5
    return 2;
    80002822:	4509                	li	a0,2
    80002824:	b761                	j	800027ac <devintr+0x1e>
      clockintr();
    80002826:	00000097          	auipc	ra,0x0
    8000282a:	f22080e7          	jalr	-222(ra) # 80002748 <clockintr>
    8000282e:	b7ed                	j	80002818 <devintr+0x8a>

0000000080002830 <usertrap>:
{
    80002830:	1101                	addi	sp,sp,-32
    80002832:	ec06                	sd	ra,24(sp)
    80002834:	e822                	sd	s0,16(sp)
    80002836:	e426                	sd	s1,8(sp)
    80002838:	e04a                	sd	s2,0(sp)
    8000283a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002840:	1007f793          	andi	a5,a5,256
    80002844:	e3ad                	bnez	a5,800028a6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002846:	00003797          	auipc	a5,0x3
    8000284a:	36a78793          	addi	a5,a5,874 # 80005bb0 <kernelvec>
    8000284e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	1ba080e7          	jalr	442(ra) # 80001a0c <myproc>
    8000285a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000285c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000285e:	14102773          	csrr	a4,sepc
    80002862:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002864:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002868:	47a1                	li	a5,8
    8000286a:	04f71c63          	bne	a4,a5,800028c2 <usertrap+0x92>
    if(p->killed)
    8000286e:	551c                	lw	a5,40(a0)
    80002870:	e3b9                	bnez	a5,800028b6 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002872:	6cb8                	ld	a4,88(s1)
    80002874:	6f1c                	ld	a5,24(a4)
    80002876:	0791                	addi	a5,a5,4
    80002878:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000287a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000287e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002882:	10079073          	csrw	sstatus,a5
    syscall();
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	2e0080e7          	jalr	736(ra) # 80002b66 <syscall>
  if(p->killed)
    8000288e:	549c                	lw	a5,40(s1)
    80002890:	ebc1                	bnez	a5,80002920 <usertrap+0xf0>
  usertrapret();
    80002892:	00000097          	auipc	ra,0x0
    80002896:	e18080e7          	jalr	-488(ra) # 800026aa <usertrapret>
}
    8000289a:	60e2                	ld	ra,24(sp)
    8000289c:	6442                	ld	s0,16(sp)
    8000289e:	64a2                	ld	s1,8(sp)
    800028a0:	6902                	ld	s2,0(sp)
    800028a2:	6105                	addi	sp,sp,32
    800028a4:	8082                	ret
    panic("usertrap: not from user mode");
    800028a6:	00006517          	auipc	a0,0x6
    800028aa:	af250513          	addi	a0,a0,-1294 # 80008398 <states.0+0x58>
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	c8c080e7          	jalr	-884(ra) # 8000053a <panic>
      exit(-1);
    800028b6:	557d                	li	a0,-1
    800028b8:	00000097          	auipc	ra,0x0
    800028bc:	aa4080e7          	jalr	-1372(ra) # 8000235c <exit>
    800028c0:	bf4d                	j	80002872 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	ecc080e7          	jalr	-308(ra) # 8000278e <devintr>
    800028ca:	892a                	mv	s2,a0
    800028cc:	c501                	beqz	a0,800028d4 <usertrap+0xa4>
  if(p->killed)
    800028ce:	549c                	lw	a5,40(s1)
    800028d0:	c3a1                	beqz	a5,80002910 <usertrap+0xe0>
    800028d2:	a815                	j	80002906 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028d8:	5890                	lw	a2,48(s1)
    800028da:	00006517          	auipc	a0,0x6
    800028de:	ade50513          	addi	a0,a0,-1314 # 800083b8 <states.0+0x78>
    800028e2:	ffffe097          	auipc	ra,0xffffe
    800028e6:	ca2080e7          	jalr	-862(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ea:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028ee:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028f2:	00006517          	auipc	a0,0x6
    800028f6:	af650513          	addi	a0,a0,-1290 # 800083e8 <states.0+0xa8>
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	c8a080e7          	jalr	-886(ra) # 80000584 <printf>
    p->killed = 1;
    80002902:	4785                	li	a5,1
    80002904:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002906:	557d                	li	a0,-1
    80002908:	00000097          	auipc	ra,0x0
    8000290c:	a54080e7          	jalr	-1452(ra) # 8000235c <exit>
  if(which_dev == 2)
    80002910:	4789                	li	a5,2
    80002912:	f8f910e3          	bne	s2,a5,80002892 <usertrap+0x62>
    yield();
    80002916:	fffff097          	auipc	ra,0xfffff
    8000291a:	7ae080e7          	jalr	1966(ra) # 800020c4 <yield>
    8000291e:	bf95                	j	80002892 <usertrap+0x62>
  int which_dev = 0;
    80002920:	4901                	li	s2,0
    80002922:	b7d5                	j	80002906 <usertrap+0xd6>

0000000080002924 <kerneltrap>:
{
    80002924:	7179                	addi	sp,sp,-48
    80002926:	f406                	sd	ra,40(sp)
    80002928:	f022                	sd	s0,32(sp)
    8000292a:	ec26                	sd	s1,24(sp)
    8000292c:	e84a                	sd	s2,16(sp)
    8000292e:	e44e                	sd	s3,8(sp)
    80002930:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002932:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002936:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000293a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000293e:	1004f793          	andi	a5,s1,256
    80002942:	cb85                	beqz	a5,80002972 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002944:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002948:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000294a:	ef85                	bnez	a5,80002982 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	e42080e7          	jalr	-446(ra) # 8000278e <devintr>
    80002954:	cd1d                	beqz	a0,80002992 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002956:	4789                	li	a5,2
    80002958:	06f50a63          	beq	a0,a5,800029cc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000295c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002960:	10049073          	csrw	sstatus,s1
}
    80002964:	70a2                	ld	ra,40(sp)
    80002966:	7402                	ld	s0,32(sp)
    80002968:	64e2                	ld	s1,24(sp)
    8000296a:	6942                	ld	s2,16(sp)
    8000296c:	69a2                	ld	s3,8(sp)
    8000296e:	6145                	addi	sp,sp,48
    80002970:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002972:	00006517          	auipc	a0,0x6
    80002976:	a9650513          	addi	a0,a0,-1386 # 80008408 <states.0+0xc8>
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	bc0080e7          	jalr	-1088(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002982:	00006517          	auipc	a0,0x6
    80002986:	aae50513          	addi	a0,a0,-1362 # 80008430 <states.0+0xf0>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	bb0080e7          	jalr	-1104(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002992:	85ce                	mv	a1,s3
    80002994:	00006517          	auipc	a0,0x6
    80002998:	abc50513          	addi	a0,a0,-1348 # 80008450 <states.0+0x110>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	be8080e7          	jalr	-1048(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029a4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029a8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ac:	00006517          	auipc	a0,0x6
    800029b0:	ab450513          	addi	a0,a0,-1356 # 80008460 <states.0+0x120>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	bd0080e7          	jalr	-1072(ra) # 80000584 <printf>
    panic("kerneltrap");
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	abc50513          	addi	a0,a0,-1348 # 80008478 <states.0+0x138>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	b76080e7          	jalr	-1162(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	040080e7          	jalr	64(ra) # 80001a0c <myproc>
    800029d4:	d541                	beqz	a0,8000295c <kerneltrap+0x38>
    800029d6:	fffff097          	auipc	ra,0xfffff
    800029da:	036080e7          	jalr	54(ra) # 80001a0c <myproc>
    800029de:	4d18                	lw	a4,24(a0)
    800029e0:	4791                	li	a5,4
    800029e2:	f6f71de3          	bne	a4,a5,8000295c <kerneltrap+0x38>
    yield();
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	6de080e7          	jalr	1758(ra) # 800020c4 <yield>
    800029ee:	b7bd                	j	8000295c <kerneltrap+0x38>

00000000800029f0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029f0:	1101                	addi	sp,sp,-32
    800029f2:	ec06                	sd	ra,24(sp)
    800029f4:	e822                	sd	s0,16(sp)
    800029f6:	e426                	sd	s1,8(sp)
    800029f8:	1000                	addi	s0,sp,32
    800029fa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029fc:	fffff097          	auipc	ra,0xfffff
    80002a00:	010080e7          	jalr	16(ra) # 80001a0c <myproc>
  switch (n) {
    80002a04:	4795                	li	a5,5
    80002a06:	0497e163          	bltu	a5,s1,80002a48 <argraw+0x58>
    80002a0a:	048a                	slli	s1,s1,0x2
    80002a0c:	00006717          	auipc	a4,0x6
    80002a10:	aa470713          	addi	a4,a4,-1372 # 800084b0 <states.0+0x170>
    80002a14:	94ba                	add	s1,s1,a4
    80002a16:	409c                	lw	a5,0(s1)
    80002a18:	97ba                	add	a5,a5,a4
    80002a1a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a1c:	6d3c                	ld	a5,88(a0)
    80002a1e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a20:	60e2                	ld	ra,24(sp)
    80002a22:	6442                	ld	s0,16(sp)
    80002a24:	64a2                	ld	s1,8(sp)
    80002a26:	6105                	addi	sp,sp,32
    80002a28:	8082                	ret
    return p->trapframe->a1;
    80002a2a:	6d3c                	ld	a5,88(a0)
    80002a2c:	7fa8                	ld	a0,120(a5)
    80002a2e:	bfcd                	j	80002a20 <argraw+0x30>
    return p->trapframe->a2;
    80002a30:	6d3c                	ld	a5,88(a0)
    80002a32:	63c8                	ld	a0,128(a5)
    80002a34:	b7f5                	j	80002a20 <argraw+0x30>
    return p->trapframe->a3;
    80002a36:	6d3c                	ld	a5,88(a0)
    80002a38:	67c8                	ld	a0,136(a5)
    80002a3a:	b7dd                	j	80002a20 <argraw+0x30>
    return p->trapframe->a4;
    80002a3c:	6d3c                	ld	a5,88(a0)
    80002a3e:	6bc8                	ld	a0,144(a5)
    80002a40:	b7c5                	j	80002a20 <argraw+0x30>
    return p->trapframe->a5;
    80002a42:	6d3c                	ld	a5,88(a0)
    80002a44:	6fc8                	ld	a0,152(a5)
    80002a46:	bfe9                	j	80002a20 <argraw+0x30>
  panic("argraw");
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	a4050513          	addi	a0,a0,-1472 # 80008488 <states.0+0x148>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080002a58 <fetchaddr>:
{
    80002a58:	1101                	addi	sp,sp,-32
    80002a5a:	ec06                	sd	ra,24(sp)
    80002a5c:	e822                	sd	s0,16(sp)
    80002a5e:	e426                	sd	s1,8(sp)
    80002a60:	e04a                	sd	s2,0(sp)
    80002a62:	1000                	addi	s0,sp,32
    80002a64:	84aa                	mv	s1,a0
    80002a66:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	fa4080e7          	jalr	-92(ra) # 80001a0c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a70:	653c                	ld	a5,72(a0)
    80002a72:	02f4f863          	bgeu	s1,a5,80002aa2 <fetchaddr+0x4a>
    80002a76:	00848713          	addi	a4,s1,8
    80002a7a:	02e7e663          	bltu	a5,a4,80002aa6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a7e:	46a1                	li	a3,8
    80002a80:	8626                	mv	a2,s1
    80002a82:	85ca                	mv	a1,s2
    80002a84:	6928                	ld	a0,80(a0)
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	c60080e7          	jalr	-928(ra) # 800016e6 <copyin>
    80002a8e:	00a03533          	snez	a0,a0
    80002a92:	40a00533          	neg	a0,a0
}
    80002a96:	60e2                	ld	ra,24(sp)
    80002a98:	6442                	ld	s0,16(sp)
    80002a9a:	64a2                	ld	s1,8(sp)
    80002a9c:	6902                	ld	s2,0(sp)
    80002a9e:	6105                	addi	sp,sp,32
    80002aa0:	8082                	ret
    return -1;
    80002aa2:	557d                	li	a0,-1
    80002aa4:	bfcd                	j	80002a96 <fetchaddr+0x3e>
    80002aa6:	557d                	li	a0,-1
    80002aa8:	b7fd                	j	80002a96 <fetchaddr+0x3e>

0000000080002aaa <fetchstr>:
{
    80002aaa:	7179                	addi	sp,sp,-48
    80002aac:	f406                	sd	ra,40(sp)
    80002aae:	f022                	sd	s0,32(sp)
    80002ab0:	ec26                	sd	s1,24(sp)
    80002ab2:	e84a                	sd	s2,16(sp)
    80002ab4:	e44e                	sd	s3,8(sp)
    80002ab6:	1800                	addi	s0,sp,48
    80002ab8:	892a                	mv	s2,a0
    80002aba:	84ae                	mv	s1,a1
    80002abc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002abe:	fffff097          	auipc	ra,0xfffff
    80002ac2:	f4e080e7          	jalr	-178(ra) # 80001a0c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ac6:	86ce                	mv	a3,s3
    80002ac8:	864a                	mv	a2,s2
    80002aca:	85a6                	mv	a1,s1
    80002acc:	6928                	ld	a0,80(a0)
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	ca6080e7          	jalr	-858(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002ad6:	00054763          	bltz	a0,80002ae4 <fetchstr+0x3a>
  return strlen(buf);
    80002ada:	8526                	mv	a0,s1
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	36c080e7          	jalr	876(ra) # 80000e48 <strlen>
}
    80002ae4:	70a2                	ld	ra,40(sp)
    80002ae6:	7402                	ld	s0,32(sp)
    80002ae8:	64e2                	ld	s1,24(sp)
    80002aea:	6942                	ld	s2,16(sp)
    80002aec:	69a2                	ld	s3,8(sp)
    80002aee:	6145                	addi	sp,sp,48
    80002af0:	8082                	ret

0000000080002af2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002af2:	1101                	addi	sp,sp,-32
    80002af4:	ec06                	sd	ra,24(sp)
    80002af6:	e822                	sd	s0,16(sp)
    80002af8:	e426                	sd	s1,8(sp)
    80002afa:	1000                	addi	s0,sp,32
    80002afc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	ef2080e7          	jalr	-270(ra) # 800029f0 <argraw>
    80002b06:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b08:	4501                	li	a0,0
    80002b0a:	60e2                	ld	ra,24(sp)
    80002b0c:	6442                	ld	s0,16(sp)
    80002b0e:	64a2                	ld	s1,8(sp)
    80002b10:	6105                	addi	sp,sp,32
    80002b12:	8082                	ret

0000000080002b14 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b14:	1101                	addi	sp,sp,-32
    80002b16:	ec06                	sd	ra,24(sp)
    80002b18:	e822                	sd	s0,16(sp)
    80002b1a:	e426                	sd	s1,8(sp)
    80002b1c:	1000                	addi	s0,sp,32
    80002b1e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b20:	00000097          	auipc	ra,0x0
    80002b24:	ed0080e7          	jalr	-304(ra) # 800029f0 <argraw>
    80002b28:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b2a:	4501                	li	a0,0
    80002b2c:	60e2                	ld	ra,24(sp)
    80002b2e:	6442                	ld	s0,16(sp)
    80002b30:	64a2                	ld	s1,8(sp)
    80002b32:	6105                	addi	sp,sp,32
    80002b34:	8082                	ret

0000000080002b36 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b36:	1101                	addi	sp,sp,-32
    80002b38:	ec06                	sd	ra,24(sp)
    80002b3a:	e822                	sd	s0,16(sp)
    80002b3c:	e426                	sd	s1,8(sp)
    80002b3e:	e04a                	sd	s2,0(sp)
    80002b40:	1000                	addi	s0,sp,32
    80002b42:	84ae                	mv	s1,a1
    80002b44:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b46:	00000097          	auipc	ra,0x0
    80002b4a:	eaa080e7          	jalr	-342(ra) # 800029f0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b4e:	864a                	mv	a2,s2
    80002b50:	85a6                	mv	a1,s1
    80002b52:	00000097          	auipc	ra,0x0
    80002b56:	f58080e7          	jalr	-168(ra) # 80002aaa <fetchstr>
}
    80002b5a:	60e2                	ld	ra,24(sp)
    80002b5c:	6442                	ld	s0,16(sp)
    80002b5e:	64a2                	ld	s1,8(sp)
    80002b60:	6902                	ld	s2,0(sp)
    80002b62:	6105                	addi	sp,sp,32
    80002b64:	8082                	ret

0000000080002b66 <syscall>:
[SYS_info]    sys_info,
};

void
syscall(void)
{
    80002b66:	1101                	addi	sp,sp,-32
    80002b68:	ec06                	sd	ra,24(sp)
    80002b6a:	e822                	sd	s0,16(sp)
    80002b6c:	e426                	sd	s1,8(sp)
    80002b6e:	e04a                	sd	s2,0(sp)
    80002b70:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b72:	fffff097          	auipc	ra,0xfffff
    80002b76:	e9a080e7          	jalr	-358(ra) # 80001a0c <myproc>
    80002b7a:	84aa                	mv	s1,a0
  p->syscallCount++;
    80002b7c:	16853783          	ld	a5,360(a0)
    80002b80:	0785                	addi	a5,a5,1
    80002b82:	16f53423          	sd	a5,360(a0)

  num = p->trapframe->a7;
    80002b86:	05853903          	ld	s2,88(a0)
    80002b8a:	0a893783          	ld	a5,168(s2)
    80002b8e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b92:	37fd                	addiw	a5,a5,-1
    80002b94:	4755                	li	a4,21
    80002b96:	00f76f63          	bltu	a4,a5,80002bb4 <syscall+0x4e>
    80002b9a:	00369713          	slli	a4,a3,0x3
    80002b9e:	00006797          	auipc	a5,0x6
    80002ba2:	92a78793          	addi	a5,a5,-1750 # 800084c8 <syscalls>
    80002ba6:	97ba                	add	a5,a5,a4
    80002ba8:	639c                	ld	a5,0(a5)
    80002baa:	c789                	beqz	a5,80002bb4 <syscall+0x4e>
    p->trapframe->a0 = syscalls[num]();
    80002bac:	9782                	jalr	a5
    80002bae:	06a93823          	sd	a0,112(s2)
    80002bb2:	a839                	j	80002bd0 <syscall+0x6a>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bb4:	15848613          	addi	a2,s1,344
    80002bb8:	588c                	lw	a1,48(s1)
    80002bba:	00006517          	auipc	a0,0x6
    80002bbe:	8d650513          	addi	a0,a0,-1834 # 80008490 <states.0+0x150>
    80002bc2:	ffffe097          	auipc	ra,0xffffe
    80002bc6:	9c2080e7          	jalr	-1598(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bca:	6cbc                	ld	a5,88(s1)
    80002bcc:	577d                	li	a4,-1
    80002bce:	fbb8                	sd	a4,112(a5)
  }
}
    80002bd0:	60e2                	ld	ra,24(sp)
    80002bd2:	6442                	ld	s0,16(sp)
    80002bd4:	64a2                	ld	s1,8(sp)
    80002bd6:	6902                	ld	s2,0(sp)
    80002bd8:	6105                	addi	sp,sp,32
    80002bda:	8082                	ret

0000000080002bdc <sys_info>:
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64 sys_info(void){
    80002bdc:	1101                	addi	sp,sp,-32
    80002bde:	ec06                	sd	ra,24(sp)
    80002be0:	e822                	sd	s0,16(sp)
    80002be2:	1000                	addi	s0,sp,32
	int n;
	argint(0,&n);
    80002be4:	fec40593          	addi	a1,s0,-20
    80002be8:	4501                	li	a0,0
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	f08080e7          	jalr	-248(ra) # 80002af2 <argint>
	printf("The value of n is %d\n", n);
    80002bf2:	fec42583          	lw	a1,-20(s0)
    80002bf6:	00006517          	auipc	a0,0x6
    80002bfa:	98a50513          	addi	a0,a0,-1654 # 80008580 <syscalls+0xb8>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	986080e7          	jalr	-1658(ra) # 80000584 <printf>
	if (n == 1){
    80002c06:	fec42783          	lw	a5,-20(s0)
    80002c0a:	4705                	li	a4,1
    80002c0c:	00e78d63          	beq	a5,a4,80002c26 <sys_info+0x4a>
		process_count_print();
	}
	else if (n == 2){
    80002c10:	4709                	li	a4,2
    80002c12:	00e78f63          	beq	a5,a4,80002c30 <sys_info+0x54>
		syscall_count_print();
	}
  else if (n == 3){
    80002c16:	470d                	li	a4,3
    80002c18:	02e78163          	beq	a5,a4,80002c3a <sys_info+0x5e>
    mem_pages_count_print();
  }
	return 0;
}
    80002c1c:	4501                	li	a0,0
    80002c1e:	60e2                	ld	ra,24(sp)
    80002c20:	6442                	ld	s0,16(sp)
    80002c22:	6105                	addi	sp,sp,32
    80002c24:	8082                	ret
		process_count_print();
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	c94080e7          	jalr	-876(ra) # 800018ba <process_count_print>
    80002c2e:	b7fd                	j	80002c1c <sys_info+0x40>
		syscall_count_print();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	e14080e7          	jalr	-492(ra) # 80001a44 <syscall_count_print>
    80002c38:	b7d5                	j	80002c1c <sys_info+0x40>
    mem_pages_count_print();
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	cc4080e7          	jalr	-828(ra) # 800018fe <mem_pages_count_print>
    80002c42:	bfe9                	j	80002c1c <sys_info+0x40>

0000000080002c44 <sys_exit>:

uint64
sys_exit(void)
{
    80002c44:	1101                	addi	sp,sp,-32
    80002c46:	ec06                	sd	ra,24(sp)
    80002c48:	e822                	sd	s0,16(sp)
    80002c4a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c4c:	fec40593          	addi	a1,s0,-20
    80002c50:	4501                	li	a0,0
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	ea0080e7          	jalr	-352(ra) # 80002af2 <argint>
    return -1;
    80002c5a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c5c:	00054963          	bltz	a0,80002c6e <sys_exit+0x2a>
  exit(n);
    80002c60:	fec42503          	lw	a0,-20(s0)
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	6f8080e7          	jalr	1784(ra) # 8000235c <exit>
  return 0;  // not reached
    80002c6c:	4781                	li	a5,0
}
    80002c6e:	853e                	mv	a0,a5
    80002c70:	60e2                	ld	ra,24(sp)
    80002c72:	6442                	ld	s0,16(sp)
    80002c74:	6105                	addi	sp,sp,32
    80002c76:	8082                	ret

0000000080002c78 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c78:	1141                	addi	sp,sp,-16
    80002c7a:	e406                	sd	ra,8(sp)
    80002c7c:	e022                	sd	s0,0(sp)
    80002c7e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	d8c080e7          	jalr	-628(ra) # 80001a0c <myproc>
}
    80002c88:	5908                	lw	a0,48(a0)
    80002c8a:	60a2                	ld	ra,8(sp)
    80002c8c:	6402                	ld	s0,0(sp)
    80002c8e:	0141                	addi	sp,sp,16
    80002c90:	8082                	ret

0000000080002c92 <sys_fork>:

uint64
sys_fork(void)
{
    80002c92:	1141                	addi	sp,sp,-16
    80002c94:	e406                	sd	ra,8(sp)
    80002c96:	e022                	sd	s0,0(sp)
    80002c98:	0800                	addi	s0,sp,16
  return fork();
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	174080e7          	jalr	372(ra) # 80001e0e <fork>
}
    80002ca2:	60a2                	ld	ra,8(sp)
    80002ca4:	6402                	ld	s0,0(sp)
    80002ca6:	0141                	addi	sp,sp,16
    80002ca8:	8082                	ret

0000000080002caa <sys_wait>:

uint64
sys_wait(void)
{
    80002caa:	1101                	addi	sp,sp,-32
    80002cac:	ec06                	sd	ra,24(sp)
    80002cae:	e822                	sd	s0,16(sp)
    80002cb0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cb2:	fe840593          	addi	a1,s0,-24
    80002cb6:	4501                	li	a0,0
    80002cb8:	00000097          	auipc	ra,0x0
    80002cbc:	e5c080e7          	jalr	-420(ra) # 80002b14 <argaddr>
    80002cc0:	87aa                	mv	a5,a0
    return -1;
    80002cc2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cc4:	0007c863          	bltz	a5,80002cd4 <sys_wait+0x2a>
  return wait(p);
    80002cc8:	fe843503          	ld	a0,-24(s0)
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	498080e7          	jalr	1176(ra) # 80002164 <wait>
}
    80002cd4:	60e2                	ld	ra,24(sp)
    80002cd6:	6442                	ld	s0,16(sp)
    80002cd8:	6105                	addi	sp,sp,32
    80002cda:	8082                	ret

0000000080002cdc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cdc:	7179                	addi	sp,sp,-48
    80002cde:	f406                	sd	ra,40(sp)
    80002ce0:	f022                	sd	s0,32(sp)
    80002ce2:	ec26                	sd	s1,24(sp)
    80002ce4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ce6:	fdc40593          	addi	a1,s0,-36
    80002cea:	4501                	li	a0,0
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	e06080e7          	jalr	-506(ra) # 80002af2 <argint>
    80002cf4:	87aa                	mv	a5,a0
    return -1;
    80002cf6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cf8:	0207c063          	bltz	a5,80002d18 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	d10080e7          	jalr	-752(ra) # 80001a0c <myproc>
    80002d04:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d06:	fdc42503          	lw	a0,-36(s0)
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	08c080e7          	jalr	140(ra) # 80001d96 <growproc>
    80002d12:	00054863          	bltz	a0,80002d22 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d16:	8526                	mv	a0,s1
}
    80002d18:	70a2                	ld	ra,40(sp)
    80002d1a:	7402                	ld	s0,32(sp)
    80002d1c:	64e2                	ld	s1,24(sp)
    80002d1e:	6145                	addi	sp,sp,48
    80002d20:	8082                	ret
    return -1;
    80002d22:	557d                	li	a0,-1
    80002d24:	bfd5                	j	80002d18 <sys_sbrk+0x3c>

0000000080002d26 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d26:	7139                	addi	sp,sp,-64
    80002d28:	fc06                	sd	ra,56(sp)
    80002d2a:	f822                	sd	s0,48(sp)
    80002d2c:	f426                	sd	s1,40(sp)
    80002d2e:	f04a                	sd	s2,32(sp)
    80002d30:	ec4e                	sd	s3,24(sp)
    80002d32:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d34:	fcc40593          	addi	a1,s0,-52
    80002d38:	4501                	li	a0,0
    80002d3a:	00000097          	auipc	ra,0x0
    80002d3e:	db8080e7          	jalr	-584(ra) # 80002af2 <argint>
    return -1;
    80002d42:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d44:	06054563          	bltz	a0,80002dae <sys_sleep+0x88>
  acquire(&tickslock);
    80002d48:	00014517          	auipc	a0,0x14
    80002d4c:	58850513          	addi	a0,a0,1416 # 800172d0 <tickslock>
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	e80080e7          	jalr	-384(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002d58:	00006917          	auipc	s2,0x6
    80002d5c:	2d892903          	lw	s2,728(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d60:	fcc42783          	lw	a5,-52(s0)
    80002d64:	cf85                	beqz	a5,80002d9c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d66:	00014997          	auipc	s3,0x14
    80002d6a:	56a98993          	addi	s3,s3,1386 # 800172d0 <tickslock>
    80002d6e:	00006497          	auipc	s1,0x6
    80002d72:	2c248493          	addi	s1,s1,706 # 80009030 <ticks>
    if(myproc()->killed){
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	c96080e7          	jalr	-874(ra) # 80001a0c <myproc>
    80002d7e:	551c                	lw	a5,40(a0)
    80002d80:	ef9d                	bnez	a5,80002dbe <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d82:	85ce                	mv	a1,s3
    80002d84:	8526                	mv	a0,s1
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	37a080e7          	jalr	890(ra) # 80002100 <sleep>
  while(ticks - ticks0 < n){
    80002d8e:	409c                	lw	a5,0(s1)
    80002d90:	412787bb          	subw	a5,a5,s2
    80002d94:	fcc42703          	lw	a4,-52(s0)
    80002d98:	fce7efe3          	bltu	a5,a4,80002d76 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d9c:	00014517          	auipc	a0,0x14
    80002da0:	53450513          	addi	a0,a0,1332 # 800172d0 <tickslock>
    80002da4:	ffffe097          	auipc	ra,0xffffe
    80002da8:	ee0080e7          	jalr	-288(ra) # 80000c84 <release>
  return 0;
    80002dac:	4781                	li	a5,0
}
    80002dae:	853e                	mv	a0,a5
    80002db0:	70e2                	ld	ra,56(sp)
    80002db2:	7442                	ld	s0,48(sp)
    80002db4:	74a2                	ld	s1,40(sp)
    80002db6:	7902                	ld	s2,32(sp)
    80002db8:	69e2                	ld	s3,24(sp)
    80002dba:	6121                	addi	sp,sp,64
    80002dbc:	8082                	ret
      release(&tickslock);
    80002dbe:	00014517          	auipc	a0,0x14
    80002dc2:	51250513          	addi	a0,a0,1298 # 800172d0 <tickslock>
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	ebe080e7          	jalr	-322(ra) # 80000c84 <release>
      return -1;
    80002dce:	57fd                	li	a5,-1
    80002dd0:	bff9                	j	80002dae <sys_sleep+0x88>

0000000080002dd2 <sys_kill>:

uint64
sys_kill(void)
{
    80002dd2:	1101                	addi	sp,sp,-32
    80002dd4:	ec06                	sd	ra,24(sp)
    80002dd6:	e822                	sd	s0,16(sp)
    80002dd8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dda:	fec40593          	addi	a1,s0,-20
    80002dde:	4501                	li	a0,0
    80002de0:	00000097          	auipc	ra,0x0
    80002de4:	d12080e7          	jalr	-750(ra) # 80002af2 <argint>
    80002de8:	87aa                	mv	a5,a0
    return -1;
    80002dea:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dec:	0007c863          	bltz	a5,80002dfc <sys_kill+0x2a>
  return kill(pid);
    80002df0:	fec42503          	lw	a0,-20(s0)
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	63e080e7          	jalr	1598(ra) # 80002432 <kill>
}
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	6105                	addi	sp,sp,32
    80002e02:	8082                	ret

0000000080002e04 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e04:	1101                	addi	sp,sp,-32
    80002e06:	ec06                	sd	ra,24(sp)
    80002e08:	e822                	sd	s0,16(sp)
    80002e0a:	e426                	sd	s1,8(sp)
    80002e0c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e0e:	00014517          	auipc	a0,0x14
    80002e12:	4c250513          	addi	a0,a0,1218 # 800172d0 <tickslock>
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	dba080e7          	jalr	-582(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002e1e:	00006497          	auipc	s1,0x6
    80002e22:	2124a483          	lw	s1,530(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e26:	00014517          	auipc	a0,0x14
    80002e2a:	4aa50513          	addi	a0,a0,1194 # 800172d0 <tickslock>
    80002e2e:	ffffe097          	auipc	ra,0xffffe
    80002e32:	e56080e7          	jalr	-426(ra) # 80000c84 <release>
  return xticks;
}
    80002e36:	02049513          	slli	a0,s1,0x20
    80002e3a:	9101                	srli	a0,a0,0x20
    80002e3c:	60e2                	ld	ra,24(sp)
    80002e3e:	6442                	ld	s0,16(sp)
    80002e40:	64a2                	ld	s1,8(sp)
    80002e42:	6105                	addi	sp,sp,32
    80002e44:	8082                	ret

0000000080002e46 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e46:	7179                	addi	sp,sp,-48
    80002e48:	f406                	sd	ra,40(sp)
    80002e4a:	f022                	sd	s0,32(sp)
    80002e4c:	ec26                	sd	s1,24(sp)
    80002e4e:	e84a                	sd	s2,16(sp)
    80002e50:	e44e                	sd	s3,8(sp)
    80002e52:	e052                	sd	s4,0(sp)
    80002e54:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e56:	00005597          	auipc	a1,0x5
    80002e5a:	74258593          	addi	a1,a1,1858 # 80008598 <syscalls+0xd0>
    80002e5e:	00014517          	auipc	a0,0x14
    80002e62:	48a50513          	addi	a0,a0,1162 # 800172e8 <bcache>
    80002e66:	ffffe097          	auipc	ra,0xffffe
    80002e6a:	cda080e7          	jalr	-806(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e6e:	0001c797          	auipc	a5,0x1c
    80002e72:	47a78793          	addi	a5,a5,1146 # 8001f2e8 <bcache+0x8000>
    80002e76:	0001c717          	auipc	a4,0x1c
    80002e7a:	6da70713          	addi	a4,a4,1754 # 8001f550 <bcache+0x8268>
    80002e7e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e82:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e86:	00014497          	auipc	s1,0x14
    80002e8a:	47a48493          	addi	s1,s1,1146 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002e8e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e90:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e92:	00005a17          	auipc	s4,0x5
    80002e96:	70ea0a13          	addi	s4,s4,1806 # 800085a0 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002e9a:	2b893783          	ld	a5,696(s2)
    80002e9e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ea0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ea4:	85d2                	mv	a1,s4
    80002ea6:	01048513          	addi	a0,s1,16
    80002eaa:	00001097          	auipc	ra,0x1
    80002eae:	4c2080e7          	jalr	1218(ra) # 8000436c <initsleeplock>
    bcache.head.next->prev = b;
    80002eb2:	2b893783          	ld	a5,696(s2)
    80002eb6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002eb8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ebc:	45848493          	addi	s1,s1,1112
    80002ec0:	fd349de3          	bne	s1,s3,80002e9a <binit+0x54>
  }
}
    80002ec4:	70a2                	ld	ra,40(sp)
    80002ec6:	7402                	ld	s0,32(sp)
    80002ec8:	64e2                	ld	s1,24(sp)
    80002eca:	6942                	ld	s2,16(sp)
    80002ecc:	69a2                	ld	s3,8(sp)
    80002ece:	6a02                	ld	s4,0(sp)
    80002ed0:	6145                	addi	sp,sp,48
    80002ed2:	8082                	ret

0000000080002ed4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ed4:	7179                	addi	sp,sp,-48
    80002ed6:	f406                	sd	ra,40(sp)
    80002ed8:	f022                	sd	s0,32(sp)
    80002eda:	ec26                	sd	s1,24(sp)
    80002edc:	e84a                	sd	s2,16(sp)
    80002ede:	e44e                	sd	s3,8(sp)
    80002ee0:	1800                	addi	s0,sp,48
    80002ee2:	892a                	mv	s2,a0
    80002ee4:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ee6:	00014517          	auipc	a0,0x14
    80002eea:	40250513          	addi	a0,a0,1026 # 800172e8 <bcache>
    80002eee:	ffffe097          	auipc	ra,0xffffe
    80002ef2:	ce2080e7          	jalr	-798(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ef6:	0001c497          	auipc	s1,0x1c
    80002efa:	6aa4b483          	ld	s1,1706(s1) # 8001f5a0 <bcache+0x82b8>
    80002efe:	0001c797          	auipc	a5,0x1c
    80002f02:	65278793          	addi	a5,a5,1618 # 8001f550 <bcache+0x8268>
    80002f06:	02f48f63          	beq	s1,a5,80002f44 <bread+0x70>
    80002f0a:	873e                	mv	a4,a5
    80002f0c:	a021                	j	80002f14 <bread+0x40>
    80002f0e:	68a4                	ld	s1,80(s1)
    80002f10:	02e48a63          	beq	s1,a4,80002f44 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f14:	449c                	lw	a5,8(s1)
    80002f16:	ff279ce3          	bne	a5,s2,80002f0e <bread+0x3a>
    80002f1a:	44dc                	lw	a5,12(s1)
    80002f1c:	ff3799e3          	bne	a5,s3,80002f0e <bread+0x3a>
      b->refcnt++;
    80002f20:	40bc                	lw	a5,64(s1)
    80002f22:	2785                	addiw	a5,a5,1
    80002f24:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f26:	00014517          	auipc	a0,0x14
    80002f2a:	3c250513          	addi	a0,a0,962 # 800172e8 <bcache>
    80002f2e:	ffffe097          	auipc	ra,0xffffe
    80002f32:	d56080e7          	jalr	-682(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002f36:	01048513          	addi	a0,s1,16
    80002f3a:	00001097          	auipc	ra,0x1
    80002f3e:	46c080e7          	jalr	1132(ra) # 800043a6 <acquiresleep>
      return b;
    80002f42:	a8b9                	j	80002fa0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f44:	0001c497          	auipc	s1,0x1c
    80002f48:	6544b483          	ld	s1,1620(s1) # 8001f598 <bcache+0x82b0>
    80002f4c:	0001c797          	auipc	a5,0x1c
    80002f50:	60478793          	addi	a5,a5,1540 # 8001f550 <bcache+0x8268>
    80002f54:	00f48863          	beq	s1,a5,80002f64 <bread+0x90>
    80002f58:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f5a:	40bc                	lw	a5,64(s1)
    80002f5c:	cf81                	beqz	a5,80002f74 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f5e:	64a4                	ld	s1,72(s1)
    80002f60:	fee49de3          	bne	s1,a4,80002f5a <bread+0x86>
  panic("bget: no buffers");
    80002f64:	00005517          	auipc	a0,0x5
    80002f68:	64450513          	addi	a0,a0,1604 # 800085a8 <syscalls+0xe0>
    80002f6c:	ffffd097          	auipc	ra,0xffffd
    80002f70:	5ce080e7          	jalr	1486(ra) # 8000053a <panic>
      b->dev = dev;
    80002f74:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f78:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f7c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f80:	4785                	li	a5,1
    80002f82:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f84:	00014517          	auipc	a0,0x14
    80002f88:	36450513          	addi	a0,a0,868 # 800172e8 <bcache>
    80002f8c:	ffffe097          	auipc	ra,0xffffe
    80002f90:	cf8080e7          	jalr	-776(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002f94:	01048513          	addi	a0,s1,16
    80002f98:	00001097          	auipc	ra,0x1
    80002f9c:	40e080e7          	jalr	1038(ra) # 800043a6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fa0:	409c                	lw	a5,0(s1)
    80002fa2:	cb89                	beqz	a5,80002fb4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fa4:	8526                	mv	a0,s1
    80002fa6:	70a2                	ld	ra,40(sp)
    80002fa8:	7402                	ld	s0,32(sp)
    80002faa:	64e2                	ld	s1,24(sp)
    80002fac:	6942                	ld	s2,16(sp)
    80002fae:	69a2                	ld	s3,8(sp)
    80002fb0:	6145                	addi	sp,sp,48
    80002fb2:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fb4:	4581                	li	a1,0
    80002fb6:	8526                	mv	a0,s1
    80002fb8:	00003097          	auipc	ra,0x3
    80002fbc:	f2a080e7          	jalr	-214(ra) # 80005ee2 <virtio_disk_rw>
    b->valid = 1;
    80002fc0:	4785                	li	a5,1
    80002fc2:	c09c                	sw	a5,0(s1)
  return b;
    80002fc4:	b7c5                	j	80002fa4 <bread+0xd0>

0000000080002fc6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fc6:	1101                	addi	sp,sp,-32
    80002fc8:	ec06                	sd	ra,24(sp)
    80002fca:	e822                	sd	s0,16(sp)
    80002fcc:	e426                	sd	s1,8(sp)
    80002fce:	1000                	addi	s0,sp,32
    80002fd0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fd2:	0541                	addi	a0,a0,16
    80002fd4:	00001097          	auipc	ra,0x1
    80002fd8:	46c080e7          	jalr	1132(ra) # 80004440 <holdingsleep>
    80002fdc:	cd01                	beqz	a0,80002ff4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fde:	4585                	li	a1,1
    80002fe0:	8526                	mv	a0,s1
    80002fe2:	00003097          	auipc	ra,0x3
    80002fe6:	f00080e7          	jalr	-256(ra) # 80005ee2 <virtio_disk_rw>
}
    80002fea:	60e2                	ld	ra,24(sp)
    80002fec:	6442                	ld	s0,16(sp)
    80002fee:	64a2                	ld	s1,8(sp)
    80002ff0:	6105                	addi	sp,sp,32
    80002ff2:	8082                	ret
    panic("bwrite");
    80002ff4:	00005517          	auipc	a0,0x5
    80002ff8:	5cc50513          	addi	a0,a0,1484 # 800085c0 <syscalls+0xf8>
    80002ffc:	ffffd097          	auipc	ra,0xffffd
    80003000:	53e080e7          	jalr	1342(ra) # 8000053a <panic>

0000000080003004 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003004:	1101                	addi	sp,sp,-32
    80003006:	ec06                	sd	ra,24(sp)
    80003008:	e822                	sd	s0,16(sp)
    8000300a:	e426                	sd	s1,8(sp)
    8000300c:	e04a                	sd	s2,0(sp)
    8000300e:	1000                	addi	s0,sp,32
    80003010:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003012:	01050913          	addi	s2,a0,16
    80003016:	854a                	mv	a0,s2
    80003018:	00001097          	auipc	ra,0x1
    8000301c:	428080e7          	jalr	1064(ra) # 80004440 <holdingsleep>
    80003020:	c92d                	beqz	a0,80003092 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003022:	854a                	mv	a0,s2
    80003024:	00001097          	auipc	ra,0x1
    80003028:	3d8080e7          	jalr	984(ra) # 800043fc <releasesleep>

  acquire(&bcache.lock);
    8000302c:	00014517          	auipc	a0,0x14
    80003030:	2bc50513          	addi	a0,a0,700 # 800172e8 <bcache>
    80003034:	ffffe097          	auipc	ra,0xffffe
    80003038:	b9c080e7          	jalr	-1124(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000303c:	40bc                	lw	a5,64(s1)
    8000303e:	37fd                	addiw	a5,a5,-1
    80003040:	0007871b          	sext.w	a4,a5
    80003044:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003046:	eb05                	bnez	a4,80003076 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003048:	68bc                	ld	a5,80(s1)
    8000304a:	64b8                	ld	a4,72(s1)
    8000304c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000304e:	64bc                	ld	a5,72(s1)
    80003050:	68b8                	ld	a4,80(s1)
    80003052:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003054:	0001c797          	auipc	a5,0x1c
    80003058:	29478793          	addi	a5,a5,660 # 8001f2e8 <bcache+0x8000>
    8000305c:	2b87b703          	ld	a4,696(a5)
    80003060:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003062:	0001c717          	auipc	a4,0x1c
    80003066:	4ee70713          	addi	a4,a4,1262 # 8001f550 <bcache+0x8268>
    8000306a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000306c:	2b87b703          	ld	a4,696(a5)
    80003070:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003072:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	27250513          	addi	a0,a0,626 # 800172e8 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	c06080e7          	jalr	-1018(ra) # 80000c84 <release>
}
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	64a2                	ld	s1,8(sp)
    8000308c:	6902                	ld	s2,0(sp)
    8000308e:	6105                	addi	sp,sp,32
    80003090:	8082                	ret
    panic("brelse");
    80003092:	00005517          	auipc	a0,0x5
    80003096:	53650513          	addi	a0,a0,1334 # 800085c8 <syscalls+0x100>
    8000309a:	ffffd097          	auipc	ra,0xffffd
    8000309e:	4a0080e7          	jalr	1184(ra) # 8000053a <panic>

00000000800030a2 <bpin>:

void
bpin(struct buf *b) {
    800030a2:	1101                	addi	sp,sp,-32
    800030a4:	ec06                	sd	ra,24(sp)
    800030a6:	e822                	sd	s0,16(sp)
    800030a8:	e426                	sd	s1,8(sp)
    800030aa:	1000                	addi	s0,sp,32
    800030ac:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030ae:	00014517          	auipc	a0,0x14
    800030b2:	23a50513          	addi	a0,a0,570 # 800172e8 <bcache>
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	b1a080e7          	jalr	-1254(ra) # 80000bd0 <acquire>
  b->refcnt++;
    800030be:	40bc                	lw	a5,64(s1)
    800030c0:	2785                	addiw	a5,a5,1
    800030c2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030c4:	00014517          	auipc	a0,0x14
    800030c8:	22450513          	addi	a0,a0,548 # 800172e8 <bcache>
    800030cc:	ffffe097          	auipc	ra,0xffffe
    800030d0:	bb8080e7          	jalr	-1096(ra) # 80000c84 <release>
}
    800030d4:	60e2                	ld	ra,24(sp)
    800030d6:	6442                	ld	s0,16(sp)
    800030d8:	64a2                	ld	s1,8(sp)
    800030da:	6105                	addi	sp,sp,32
    800030dc:	8082                	ret

00000000800030de <bunpin>:

void
bunpin(struct buf *b) {
    800030de:	1101                	addi	sp,sp,-32
    800030e0:	ec06                	sd	ra,24(sp)
    800030e2:	e822                	sd	s0,16(sp)
    800030e4:	e426                	sd	s1,8(sp)
    800030e6:	1000                	addi	s0,sp,32
    800030e8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030ea:	00014517          	auipc	a0,0x14
    800030ee:	1fe50513          	addi	a0,a0,510 # 800172e8 <bcache>
    800030f2:	ffffe097          	auipc	ra,0xffffe
    800030f6:	ade080e7          	jalr	-1314(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800030fa:	40bc                	lw	a5,64(s1)
    800030fc:	37fd                	addiw	a5,a5,-1
    800030fe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003100:	00014517          	auipc	a0,0x14
    80003104:	1e850513          	addi	a0,a0,488 # 800172e8 <bcache>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	b7c080e7          	jalr	-1156(ra) # 80000c84 <release>
}
    80003110:	60e2                	ld	ra,24(sp)
    80003112:	6442                	ld	s0,16(sp)
    80003114:	64a2                	ld	s1,8(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret

000000008000311a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	e426                	sd	s1,8(sp)
    80003122:	e04a                	sd	s2,0(sp)
    80003124:	1000                	addi	s0,sp,32
    80003126:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003128:	00d5d59b          	srliw	a1,a1,0xd
    8000312c:	0001d797          	auipc	a5,0x1d
    80003130:	8987a783          	lw	a5,-1896(a5) # 8001f9c4 <sb+0x1c>
    80003134:	9dbd                	addw	a1,a1,a5
    80003136:	00000097          	auipc	ra,0x0
    8000313a:	d9e080e7          	jalr	-610(ra) # 80002ed4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000313e:	0074f713          	andi	a4,s1,7
    80003142:	4785                	li	a5,1
    80003144:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003148:	14ce                	slli	s1,s1,0x33
    8000314a:	90d9                	srli	s1,s1,0x36
    8000314c:	00950733          	add	a4,a0,s1
    80003150:	05874703          	lbu	a4,88(a4)
    80003154:	00e7f6b3          	and	a3,a5,a4
    80003158:	c69d                	beqz	a3,80003186 <bfree+0x6c>
    8000315a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000315c:	94aa                	add	s1,s1,a0
    8000315e:	fff7c793          	not	a5,a5
    80003162:	8f7d                	and	a4,a4,a5
    80003164:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003168:	00001097          	auipc	ra,0x1
    8000316c:	120080e7          	jalr	288(ra) # 80004288 <log_write>
  brelse(bp);
    80003170:	854a                	mv	a0,s2
    80003172:	00000097          	auipc	ra,0x0
    80003176:	e92080e7          	jalr	-366(ra) # 80003004 <brelse>
}
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	64a2                	ld	s1,8(sp)
    80003180:	6902                	ld	s2,0(sp)
    80003182:	6105                	addi	sp,sp,32
    80003184:	8082                	ret
    panic("freeing free block");
    80003186:	00005517          	auipc	a0,0x5
    8000318a:	44a50513          	addi	a0,a0,1098 # 800085d0 <syscalls+0x108>
    8000318e:	ffffd097          	auipc	ra,0xffffd
    80003192:	3ac080e7          	jalr	940(ra) # 8000053a <panic>

0000000080003196 <balloc>:
{
    80003196:	711d                	addi	sp,sp,-96
    80003198:	ec86                	sd	ra,88(sp)
    8000319a:	e8a2                	sd	s0,80(sp)
    8000319c:	e4a6                	sd	s1,72(sp)
    8000319e:	e0ca                	sd	s2,64(sp)
    800031a0:	fc4e                	sd	s3,56(sp)
    800031a2:	f852                	sd	s4,48(sp)
    800031a4:	f456                	sd	s5,40(sp)
    800031a6:	f05a                	sd	s6,32(sp)
    800031a8:	ec5e                	sd	s7,24(sp)
    800031aa:	e862                	sd	s8,16(sp)
    800031ac:	e466                	sd	s9,8(sp)
    800031ae:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031b0:	0001c797          	auipc	a5,0x1c
    800031b4:	7fc7a783          	lw	a5,2044(a5) # 8001f9ac <sb+0x4>
    800031b8:	cbc1                	beqz	a5,80003248 <balloc+0xb2>
    800031ba:	8baa                	mv	s7,a0
    800031bc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031be:	0001cb17          	auipc	s6,0x1c
    800031c2:	7eab0b13          	addi	s6,s6,2026 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031c6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031c8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ca:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031cc:	6c89                	lui	s9,0x2
    800031ce:	a831                	j	800031ea <balloc+0x54>
    brelse(bp);
    800031d0:	854a                	mv	a0,s2
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	e32080e7          	jalr	-462(ra) # 80003004 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031da:	015c87bb          	addw	a5,s9,s5
    800031de:	00078a9b          	sext.w	s5,a5
    800031e2:	004b2703          	lw	a4,4(s6)
    800031e6:	06eaf163          	bgeu	s5,a4,80003248 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800031ea:	41fad79b          	sraiw	a5,s5,0x1f
    800031ee:	0137d79b          	srliw	a5,a5,0x13
    800031f2:	015787bb          	addw	a5,a5,s5
    800031f6:	40d7d79b          	sraiw	a5,a5,0xd
    800031fa:	01cb2583          	lw	a1,28(s6)
    800031fe:	9dbd                	addw	a1,a1,a5
    80003200:	855e                	mv	a0,s7
    80003202:	00000097          	auipc	ra,0x0
    80003206:	cd2080e7          	jalr	-814(ra) # 80002ed4 <bread>
    8000320a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000320c:	004b2503          	lw	a0,4(s6)
    80003210:	000a849b          	sext.w	s1,s5
    80003214:	8762                	mv	a4,s8
    80003216:	faa4fde3          	bgeu	s1,a0,800031d0 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000321a:	00777693          	andi	a3,a4,7
    8000321e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003222:	41f7579b          	sraiw	a5,a4,0x1f
    80003226:	01d7d79b          	srliw	a5,a5,0x1d
    8000322a:	9fb9                	addw	a5,a5,a4
    8000322c:	4037d79b          	sraiw	a5,a5,0x3
    80003230:	00f90633          	add	a2,s2,a5
    80003234:	05864603          	lbu	a2,88(a2)
    80003238:	00c6f5b3          	and	a1,a3,a2
    8000323c:	cd91                	beqz	a1,80003258 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000323e:	2705                	addiw	a4,a4,1
    80003240:	2485                	addiw	s1,s1,1
    80003242:	fd471ae3          	bne	a4,s4,80003216 <balloc+0x80>
    80003246:	b769                	j	800031d0 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003248:	00005517          	auipc	a0,0x5
    8000324c:	3a050513          	addi	a0,a0,928 # 800085e8 <syscalls+0x120>
    80003250:	ffffd097          	auipc	ra,0xffffd
    80003254:	2ea080e7          	jalr	746(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003258:	97ca                	add	a5,a5,s2
    8000325a:	8e55                	or	a2,a2,a3
    8000325c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003260:	854a                	mv	a0,s2
    80003262:	00001097          	auipc	ra,0x1
    80003266:	026080e7          	jalr	38(ra) # 80004288 <log_write>
        brelse(bp);
    8000326a:	854a                	mv	a0,s2
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	d98080e7          	jalr	-616(ra) # 80003004 <brelse>
  bp = bread(dev, bno);
    80003274:	85a6                	mv	a1,s1
    80003276:	855e                	mv	a0,s7
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	c5c080e7          	jalr	-932(ra) # 80002ed4 <bread>
    80003280:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003282:	40000613          	li	a2,1024
    80003286:	4581                	li	a1,0
    80003288:	05850513          	addi	a0,a0,88
    8000328c:	ffffe097          	auipc	ra,0xffffe
    80003290:	a40080e7          	jalr	-1472(ra) # 80000ccc <memset>
  log_write(bp);
    80003294:	854a                	mv	a0,s2
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	ff2080e7          	jalr	-14(ra) # 80004288 <log_write>
  brelse(bp);
    8000329e:	854a                	mv	a0,s2
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	d64080e7          	jalr	-668(ra) # 80003004 <brelse>
}
    800032a8:	8526                	mv	a0,s1
    800032aa:	60e6                	ld	ra,88(sp)
    800032ac:	6446                	ld	s0,80(sp)
    800032ae:	64a6                	ld	s1,72(sp)
    800032b0:	6906                	ld	s2,64(sp)
    800032b2:	79e2                	ld	s3,56(sp)
    800032b4:	7a42                	ld	s4,48(sp)
    800032b6:	7aa2                	ld	s5,40(sp)
    800032b8:	7b02                	ld	s6,32(sp)
    800032ba:	6be2                	ld	s7,24(sp)
    800032bc:	6c42                	ld	s8,16(sp)
    800032be:	6ca2                	ld	s9,8(sp)
    800032c0:	6125                	addi	sp,sp,96
    800032c2:	8082                	ret

00000000800032c4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032c4:	7179                	addi	sp,sp,-48
    800032c6:	f406                	sd	ra,40(sp)
    800032c8:	f022                	sd	s0,32(sp)
    800032ca:	ec26                	sd	s1,24(sp)
    800032cc:	e84a                	sd	s2,16(sp)
    800032ce:	e44e                	sd	s3,8(sp)
    800032d0:	e052                	sd	s4,0(sp)
    800032d2:	1800                	addi	s0,sp,48
    800032d4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032d6:	47ad                	li	a5,11
    800032d8:	04b7fe63          	bgeu	a5,a1,80003334 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032dc:	ff45849b          	addiw	s1,a1,-12
    800032e0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032e4:	0ff00793          	li	a5,255
    800032e8:	0ae7e463          	bltu	a5,a4,80003390 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032ec:	08052583          	lw	a1,128(a0)
    800032f0:	c5b5                	beqz	a1,8000335c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032f2:	00092503          	lw	a0,0(s2)
    800032f6:	00000097          	auipc	ra,0x0
    800032fa:	bde080e7          	jalr	-1058(ra) # 80002ed4 <bread>
    800032fe:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003300:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003304:	02049713          	slli	a4,s1,0x20
    80003308:	01e75593          	srli	a1,a4,0x1e
    8000330c:	00b784b3          	add	s1,a5,a1
    80003310:	0004a983          	lw	s3,0(s1)
    80003314:	04098e63          	beqz	s3,80003370 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003318:	8552                	mv	a0,s4
    8000331a:	00000097          	auipc	ra,0x0
    8000331e:	cea080e7          	jalr	-790(ra) # 80003004 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003322:	854e                	mv	a0,s3
    80003324:	70a2                	ld	ra,40(sp)
    80003326:	7402                	ld	s0,32(sp)
    80003328:	64e2                	ld	s1,24(sp)
    8000332a:	6942                	ld	s2,16(sp)
    8000332c:	69a2                	ld	s3,8(sp)
    8000332e:	6a02                	ld	s4,0(sp)
    80003330:	6145                	addi	sp,sp,48
    80003332:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003334:	02059793          	slli	a5,a1,0x20
    80003338:	01e7d593          	srli	a1,a5,0x1e
    8000333c:	00b504b3          	add	s1,a0,a1
    80003340:	0504a983          	lw	s3,80(s1)
    80003344:	fc099fe3          	bnez	s3,80003322 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003348:	4108                	lw	a0,0(a0)
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	e4c080e7          	jalr	-436(ra) # 80003196 <balloc>
    80003352:	0005099b          	sext.w	s3,a0
    80003356:	0534a823          	sw	s3,80(s1)
    8000335a:	b7e1                	j	80003322 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000335c:	4108                	lw	a0,0(a0)
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	e38080e7          	jalr	-456(ra) # 80003196 <balloc>
    80003366:	0005059b          	sext.w	a1,a0
    8000336a:	08b92023          	sw	a1,128(s2)
    8000336e:	b751                	j	800032f2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003370:	00092503          	lw	a0,0(s2)
    80003374:	00000097          	auipc	ra,0x0
    80003378:	e22080e7          	jalr	-478(ra) # 80003196 <balloc>
    8000337c:	0005099b          	sext.w	s3,a0
    80003380:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003384:	8552                	mv	a0,s4
    80003386:	00001097          	auipc	ra,0x1
    8000338a:	f02080e7          	jalr	-254(ra) # 80004288 <log_write>
    8000338e:	b769                	j	80003318 <bmap+0x54>
  panic("bmap: out of range");
    80003390:	00005517          	auipc	a0,0x5
    80003394:	27050513          	addi	a0,a0,624 # 80008600 <syscalls+0x138>
    80003398:	ffffd097          	auipc	ra,0xffffd
    8000339c:	1a2080e7          	jalr	418(ra) # 8000053a <panic>

00000000800033a0 <iget>:
{
    800033a0:	7179                	addi	sp,sp,-48
    800033a2:	f406                	sd	ra,40(sp)
    800033a4:	f022                	sd	s0,32(sp)
    800033a6:	ec26                	sd	s1,24(sp)
    800033a8:	e84a                	sd	s2,16(sp)
    800033aa:	e44e                	sd	s3,8(sp)
    800033ac:	e052                	sd	s4,0(sp)
    800033ae:	1800                	addi	s0,sp,48
    800033b0:	89aa                	mv	s3,a0
    800033b2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033b4:	0001c517          	auipc	a0,0x1c
    800033b8:	61450513          	addi	a0,a0,1556 # 8001f9c8 <itable>
    800033bc:	ffffe097          	auipc	ra,0xffffe
    800033c0:	814080e7          	jalr	-2028(ra) # 80000bd0 <acquire>
  empty = 0;
    800033c4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033c6:	0001c497          	auipc	s1,0x1c
    800033ca:	61a48493          	addi	s1,s1,1562 # 8001f9e0 <itable+0x18>
    800033ce:	0001e697          	auipc	a3,0x1e
    800033d2:	0a268693          	addi	a3,a3,162 # 80021470 <log>
    800033d6:	a039                	j	800033e4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033d8:	02090b63          	beqz	s2,8000340e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033dc:	08848493          	addi	s1,s1,136
    800033e0:	02d48a63          	beq	s1,a3,80003414 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033e4:	449c                	lw	a5,8(s1)
    800033e6:	fef059e3          	blez	a5,800033d8 <iget+0x38>
    800033ea:	4098                	lw	a4,0(s1)
    800033ec:	ff3716e3          	bne	a4,s3,800033d8 <iget+0x38>
    800033f0:	40d8                	lw	a4,4(s1)
    800033f2:	ff4713e3          	bne	a4,s4,800033d8 <iget+0x38>
      ip->ref++;
    800033f6:	2785                	addiw	a5,a5,1
    800033f8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033fa:	0001c517          	auipc	a0,0x1c
    800033fe:	5ce50513          	addi	a0,a0,1486 # 8001f9c8 <itable>
    80003402:	ffffe097          	auipc	ra,0xffffe
    80003406:	882080e7          	jalr	-1918(ra) # 80000c84 <release>
      return ip;
    8000340a:	8926                	mv	s2,s1
    8000340c:	a03d                	j	8000343a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000340e:	f7f9                	bnez	a5,800033dc <iget+0x3c>
    80003410:	8926                	mv	s2,s1
    80003412:	b7e9                	j	800033dc <iget+0x3c>
  if(empty == 0)
    80003414:	02090c63          	beqz	s2,8000344c <iget+0xac>
  ip->dev = dev;
    80003418:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000341c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003420:	4785                	li	a5,1
    80003422:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003426:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000342a:	0001c517          	auipc	a0,0x1c
    8000342e:	59e50513          	addi	a0,a0,1438 # 8001f9c8 <itable>
    80003432:	ffffe097          	auipc	ra,0xffffe
    80003436:	852080e7          	jalr	-1966(ra) # 80000c84 <release>
}
    8000343a:	854a                	mv	a0,s2
    8000343c:	70a2                	ld	ra,40(sp)
    8000343e:	7402                	ld	s0,32(sp)
    80003440:	64e2                	ld	s1,24(sp)
    80003442:	6942                	ld	s2,16(sp)
    80003444:	69a2                	ld	s3,8(sp)
    80003446:	6a02                	ld	s4,0(sp)
    80003448:	6145                	addi	sp,sp,48
    8000344a:	8082                	ret
    panic("iget: no inodes");
    8000344c:	00005517          	auipc	a0,0x5
    80003450:	1cc50513          	addi	a0,a0,460 # 80008618 <syscalls+0x150>
    80003454:	ffffd097          	auipc	ra,0xffffd
    80003458:	0e6080e7          	jalr	230(ra) # 8000053a <panic>

000000008000345c <fsinit>:
fsinit(int dev) {
    8000345c:	7179                	addi	sp,sp,-48
    8000345e:	f406                	sd	ra,40(sp)
    80003460:	f022                	sd	s0,32(sp)
    80003462:	ec26                	sd	s1,24(sp)
    80003464:	e84a                	sd	s2,16(sp)
    80003466:	e44e                	sd	s3,8(sp)
    80003468:	1800                	addi	s0,sp,48
    8000346a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000346c:	4585                	li	a1,1
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	a66080e7          	jalr	-1434(ra) # 80002ed4 <bread>
    80003476:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003478:	0001c997          	auipc	s3,0x1c
    8000347c:	53098993          	addi	s3,s3,1328 # 8001f9a8 <sb>
    80003480:	02000613          	li	a2,32
    80003484:	05850593          	addi	a1,a0,88
    80003488:	854e                	mv	a0,s3
    8000348a:	ffffe097          	auipc	ra,0xffffe
    8000348e:	89e080e7          	jalr	-1890(ra) # 80000d28 <memmove>
  brelse(bp);
    80003492:	8526                	mv	a0,s1
    80003494:	00000097          	auipc	ra,0x0
    80003498:	b70080e7          	jalr	-1168(ra) # 80003004 <brelse>
  if(sb.magic != FSMAGIC)
    8000349c:	0009a703          	lw	a4,0(s3)
    800034a0:	102037b7          	lui	a5,0x10203
    800034a4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034a8:	02f71263          	bne	a4,a5,800034cc <fsinit+0x70>
  initlog(dev, &sb);
    800034ac:	0001c597          	auipc	a1,0x1c
    800034b0:	4fc58593          	addi	a1,a1,1276 # 8001f9a8 <sb>
    800034b4:	854a                	mv	a0,s2
    800034b6:	00001097          	auipc	ra,0x1
    800034ba:	b56080e7          	jalr	-1194(ra) # 8000400c <initlog>
}
    800034be:	70a2                	ld	ra,40(sp)
    800034c0:	7402                	ld	s0,32(sp)
    800034c2:	64e2                	ld	s1,24(sp)
    800034c4:	6942                	ld	s2,16(sp)
    800034c6:	69a2                	ld	s3,8(sp)
    800034c8:	6145                	addi	sp,sp,48
    800034ca:	8082                	ret
    panic("invalid file system");
    800034cc:	00005517          	auipc	a0,0x5
    800034d0:	15c50513          	addi	a0,a0,348 # 80008628 <syscalls+0x160>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	066080e7          	jalr	102(ra) # 8000053a <panic>

00000000800034dc <iinit>:
{
    800034dc:	7179                	addi	sp,sp,-48
    800034de:	f406                	sd	ra,40(sp)
    800034e0:	f022                	sd	s0,32(sp)
    800034e2:	ec26                	sd	s1,24(sp)
    800034e4:	e84a                	sd	s2,16(sp)
    800034e6:	e44e                	sd	s3,8(sp)
    800034e8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034ea:	00005597          	auipc	a1,0x5
    800034ee:	15658593          	addi	a1,a1,342 # 80008640 <syscalls+0x178>
    800034f2:	0001c517          	auipc	a0,0x1c
    800034f6:	4d650513          	addi	a0,a0,1238 # 8001f9c8 <itable>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	646080e7          	jalr	1606(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003502:	0001c497          	auipc	s1,0x1c
    80003506:	4ee48493          	addi	s1,s1,1262 # 8001f9f0 <itable+0x28>
    8000350a:	0001e997          	auipc	s3,0x1e
    8000350e:	f7698993          	addi	s3,s3,-138 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003512:	00005917          	auipc	s2,0x5
    80003516:	13690913          	addi	s2,s2,310 # 80008648 <syscalls+0x180>
    8000351a:	85ca                	mv	a1,s2
    8000351c:	8526                	mv	a0,s1
    8000351e:	00001097          	auipc	ra,0x1
    80003522:	e4e080e7          	jalr	-434(ra) # 8000436c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003526:	08848493          	addi	s1,s1,136
    8000352a:	ff3498e3          	bne	s1,s3,8000351a <iinit+0x3e>
}
    8000352e:	70a2                	ld	ra,40(sp)
    80003530:	7402                	ld	s0,32(sp)
    80003532:	64e2                	ld	s1,24(sp)
    80003534:	6942                	ld	s2,16(sp)
    80003536:	69a2                	ld	s3,8(sp)
    80003538:	6145                	addi	sp,sp,48
    8000353a:	8082                	ret

000000008000353c <ialloc>:
{
    8000353c:	715d                	addi	sp,sp,-80
    8000353e:	e486                	sd	ra,72(sp)
    80003540:	e0a2                	sd	s0,64(sp)
    80003542:	fc26                	sd	s1,56(sp)
    80003544:	f84a                	sd	s2,48(sp)
    80003546:	f44e                	sd	s3,40(sp)
    80003548:	f052                	sd	s4,32(sp)
    8000354a:	ec56                	sd	s5,24(sp)
    8000354c:	e85a                	sd	s6,16(sp)
    8000354e:	e45e                	sd	s7,8(sp)
    80003550:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003552:	0001c717          	auipc	a4,0x1c
    80003556:	46272703          	lw	a4,1122(a4) # 8001f9b4 <sb+0xc>
    8000355a:	4785                	li	a5,1
    8000355c:	04e7fa63          	bgeu	a5,a4,800035b0 <ialloc+0x74>
    80003560:	8aaa                	mv	s5,a0
    80003562:	8bae                	mv	s7,a1
    80003564:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003566:	0001ca17          	auipc	s4,0x1c
    8000356a:	442a0a13          	addi	s4,s4,1090 # 8001f9a8 <sb>
    8000356e:	00048b1b          	sext.w	s6,s1
    80003572:	0044d593          	srli	a1,s1,0x4
    80003576:	018a2783          	lw	a5,24(s4)
    8000357a:	9dbd                	addw	a1,a1,a5
    8000357c:	8556                	mv	a0,s5
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	956080e7          	jalr	-1706(ra) # 80002ed4 <bread>
    80003586:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003588:	05850993          	addi	s3,a0,88
    8000358c:	00f4f793          	andi	a5,s1,15
    80003590:	079a                	slli	a5,a5,0x6
    80003592:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003594:	00099783          	lh	a5,0(s3)
    80003598:	c785                	beqz	a5,800035c0 <ialloc+0x84>
    brelse(bp);
    8000359a:	00000097          	auipc	ra,0x0
    8000359e:	a6a080e7          	jalr	-1430(ra) # 80003004 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035a2:	0485                	addi	s1,s1,1
    800035a4:	00ca2703          	lw	a4,12(s4)
    800035a8:	0004879b          	sext.w	a5,s1
    800035ac:	fce7e1e3          	bltu	a5,a4,8000356e <ialloc+0x32>
  panic("ialloc: no inodes");
    800035b0:	00005517          	auipc	a0,0x5
    800035b4:	0a050513          	addi	a0,a0,160 # 80008650 <syscalls+0x188>
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	f82080e7          	jalr	-126(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    800035c0:	04000613          	li	a2,64
    800035c4:	4581                	li	a1,0
    800035c6:	854e                	mv	a0,s3
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	704080e7          	jalr	1796(ra) # 80000ccc <memset>
      dip->type = type;
    800035d0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035d4:	854a                	mv	a0,s2
    800035d6:	00001097          	auipc	ra,0x1
    800035da:	cb2080e7          	jalr	-846(ra) # 80004288 <log_write>
      brelse(bp);
    800035de:	854a                	mv	a0,s2
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	a24080e7          	jalr	-1500(ra) # 80003004 <brelse>
      return iget(dev, inum);
    800035e8:	85da                	mv	a1,s6
    800035ea:	8556                	mv	a0,s5
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	db4080e7          	jalr	-588(ra) # 800033a0 <iget>
}
    800035f4:	60a6                	ld	ra,72(sp)
    800035f6:	6406                	ld	s0,64(sp)
    800035f8:	74e2                	ld	s1,56(sp)
    800035fa:	7942                	ld	s2,48(sp)
    800035fc:	79a2                	ld	s3,40(sp)
    800035fe:	7a02                	ld	s4,32(sp)
    80003600:	6ae2                	ld	s5,24(sp)
    80003602:	6b42                	ld	s6,16(sp)
    80003604:	6ba2                	ld	s7,8(sp)
    80003606:	6161                	addi	sp,sp,80
    80003608:	8082                	ret

000000008000360a <iupdate>:
{
    8000360a:	1101                	addi	sp,sp,-32
    8000360c:	ec06                	sd	ra,24(sp)
    8000360e:	e822                	sd	s0,16(sp)
    80003610:	e426                	sd	s1,8(sp)
    80003612:	e04a                	sd	s2,0(sp)
    80003614:	1000                	addi	s0,sp,32
    80003616:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003618:	415c                	lw	a5,4(a0)
    8000361a:	0047d79b          	srliw	a5,a5,0x4
    8000361e:	0001c597          	auipc	a1,0x1c
    80003622:	3a25a583          	lw	a1,930(a1) # 8001f9c0 <sb+0x18>
    80003626:	9dbd                	addw	a1,a1,a5
    80003628:	4108                	lw	a0,0(a0)
    8000362a:	00000097          	auipc	ra,0x0
    8000362e:	8aa080e7          	jalr	-1878(ra) # 80002ed4 <bread>
    80003632:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003634:	05850793          	addi	a5,a0,88
    80003638:	40d8                	lw	a4,4(s1)
    8000363a:	8b3d                	andi	a4,a4,15
    8000363c:	071a                	slli	a4,a4,0x6
    8000363e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003640:	04449703          	lh	a4,68(s1)
    80003644:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003648:	04649703          	lh	a4,70(s1)
    8000364c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003650:	04849703          	lh	a4,72(s1)
    80003654:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003658:	04a49703          	lh	a4,74(s1)
    8000365c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003660:	44f8                	lw	a4,76(s1)
    80003662:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003664:	03400613          	li	a2,52
    80003668:	05048593          	addi	a1,s1,80
    8000366c:	00c78513          	addi	a0,a5,12
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	6b8080e7          	jalr	1720(ra) # 80000d28 <memmove>
  log_write(bp);
    80003678:	854a                	mv	a0,s2
    8000367a:	00001097          	auipc	ra,0x1
    8000367e:	c0e080e7          	jalr	-1010(ra) # 80004288 <log_write>
  brelse(bp);
    80003682:	854a                	mv	a0,s2
    80003684:	00000097          	auipc	ra,0x0
    80003688:	980080e7          	jalr	-1664(ra) # 80003004 <brelse>
}
    8000368c:	60e2                	ld	ra,24(sp)
    8000368e:	6442                	ld	s0,16(sp)
    80003690:	64a2                	ld	s1,8(sp)
    80003692:	6902                	ld	s2,0(sp)
    80003694:	6105                	addi	sp,sp,32
    80003696:	8082                	ret

0000000080003698 <idup>:
{
    80003698:	1101                	addi	sp,sp,-32
    8000369a:	ec06                	sd	ra,24(sp)
    8000369c:	e822                	sd	s0,16(sp)
    8000369e:	e426                	sd	s1,8(sp)
    800036a0:	1000                	addi	s0,sp,32
    800036a2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036a4:	0001c517          	auipc	a0,0x1c
    800036a8:	32450513          	addi	a0,a0,804 # 8001f9c8 <itable>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	524080e7          	jalr	1316(ra) # 80000bd0 <acquire>
  ip->ref++;
    800036b4:	449c                	lw	a5,8(s1)
    800036b6:	2785                	addiw	a5,a5,1
    800036b8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036ba:	0001c517          	auipc	a0,0x1c
    800036be:	30e50513          	addi	a0,a0,782 # 8001f9c8 <itable>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	5c2080e7          	jalr	1474(ra) # 80000c84 <release>
}
    800036ca:	8526                	mv	a0,s1
    800036cc:	60e2                	ld	ra,24(sp)
    800036ce:	6442                	ld	s0,16(sp)
    800036d0:	64a2                	ld	s1,8(sp)
    800036d2:	6105                	addi	sp,sp,32
    800036d4:	8082                	ret

00000000800036d6 <ilock>:
{
    800036d6:	1101                	addi	sp,sp,-32
    800036d8:	ec06                	sd	ra,24(sp)
    800036da:	e822                	sd	s0,16(sp)
    800036dc:	e426                	sd	s1,8(sp)
    800036de:	e04a                	sd	s2,0(sp)
    800036e0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036e2:	c115                	beqz	a0,80003706 <ilock+0x30>
    800036e4:	84aa                	mv	s1,a0
    800036e6:	451c                	lw	a5,8(a0)
    800036e8:	00f05f63          	blez	a5,80003706 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036ec:	0541                	addi	a0,a0,16
    800036ee:	00001097          	auipc	ra,0x1
    800036f2:	cb8080e7          	jalr	-840(ra) # 800043a6 <acquiresleep>
  if(ip->valid == 0){
    800036f6:	40bc                	lw	a5,64(s1)
    800036f8:	cf99                	beqz	a5,80003716 <ilock+0x40>
}
    800036fa:	60e2                	ld	ra,24(sp)
    800036fc:	6442                	ld	s0,16(sp)
    800036fe:	64a2                	ld	s1,8(sp)
    80003700:	6902                	ld	s2,0(sp)
    80003702:	6105                	addi	sp,sp,32
    80003704:	8082                	ret
    panic("ilock");
    80003706:	00005517          	auipc	a0,0x5
    8000370a:	f6250513          	addi	a0,a0,-158 # 80008668 <syscalls+0x1a0>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	e2c080e7          	jalr	-468(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003716:	40dc                	lw	a5,4(s1)
    80003718:	0047d79b          	srliw	a5,a5,0x4
    8000371c:	0001c597          	auipc	a1,0x1c
    80003720:	2a45a583          	lw	a1,676(a1) # 8001f9c0 <sb+0x18>
    80003724:	9dbd                	addw	a1,a1,a5
    80003726:	4088                	lw	a0,0(s1)
    80003728:	fffff097          	auipc	ra,0xfffff
    8000372c:	7ac080e7          	jalr	1964(ra) # 80002ed4 <bread>
    80003730:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003732:	05850593          	addi	a1,a0,88
    80003736:	40dc                	lw	a5,4(s1)
    80003738:	8bbd                	andi	a5,a5,15
    8000373a:	079a                	slli	a5,a5,0x6
    8000373c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000373e:	00059783          	lh	a5,0(a1)
    80003742:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003746:	00259783          	lh	a5,2(a1)
    8000374a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000374e:	00459783          	lh	a5,4(a1)
    80003752:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003756:	00659783          	lh	a5,6(a1)
    8000375a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000375e:	459c                	lw	a5,8(a1)
    80003760:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003762:	03400613          	li	a2,52
    80003766:	05b1                	addi	a1,a1,12
    80003768:	05048513          	addi	a0,s1,80
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	5bc080e7          	jalr	1468(ra) # 80000d28 <memmove>
    brelse(bp);
    80003774:	854a                	mv	a0,s2
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	88e080e7          	jalr	-1906(ra) # 80003004 <brelse>
    ip->valid = 1;
    8000377e:	4785                	li	a5,1
    80003780:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003782:	04449783          	lh	a5,68(s1)
    80003786:	fbb5                	bnez	a5,800036fa <ilock+0x24>
      panic("ilock: no type");
    80003788:	00005517          	auipc	a0,0x5
    8000378c:	ee850513          	addi	a0,a0,-280 # 80008670 <syscalls+0x1a8>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	daa080e7          	jalr	-598(ra) # 8000053a <panic>

0000000080003798 <iunlock>:
{
    80003798:	1101                	addi	sp,sp,-32
    8000379a:	ec06                	sd	ra,24(sp)
    8000379c:	e822                	sd	s0,16(sp)
    8000379e:	e426                	sd	s1,8(sp)
    800037a0:	e04a                	sd	s2,0(sp)
    800037a2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037a4:	c905                	beqz	a0,800037d4 <iunlock+0x3c>
    800037a6:	84aa                	mv	s1,a0
    800037a8:	01050913          	addi	s2,a0,16
    800037ac:	854a                	mv	a0,s2
    800037ae:	00001097          	auipc	ra,0x1
    800037b2:	c92080e7          	jalr	-878(ra) # 80004440 <holdingsleep>
    800037b6:	cd19                	beqz	a0,800037d4 <iunlock+0x3c>
    800037b8:	449c                	lw	a5,8(s1)
    800037ba:	00f05d63          	blez	a5,800037d4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037be:	854a                	mv	a0,s2
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	c3c080e7          	jalr	-964(ra) # 800043fc <releasesleep>
}
    800037c8:	60e2                	ld	ra,24(sp)
    800037ca:	6442                	ld	s0,16(sp)
    800037cc:	64a2                	ld	s1,8(sp)
    800037ce:	6902                	ld	s2,0(sp)
    800037d0:	6105                	addi	sp,sp,32
    800037d2:	8082                	ret
    panic("iunlock");
    800037d4:	00005517          	auipc	a0,0x5
    800037d8:	eac50513          	addi	a0,a0,-340 # 80008680 <syscalls+0x1b8>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	d5e080e7          	jalr	-674(ra) # 8000053a <panic>

00000000800037e4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037e4:	7179                	addi	sp,sp,-48
    800037e6:	f406                	sd	ra,40(sp)
    800037e8:	f022                	sd	s0,32(sp)
    800037ea:	ec26                	sd	s1,24(sp)
    800037ec:	e84a                	sd	s2,16(sp)
    800037ee:	e44e                	sd	s3,8(sp)
    800037f0:	e052                	sd	s4,0(sp)
    800037f2:	1800                	addi	s0,sp,48
    800037f4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037f6:	05050493          	addi	s1,a0,80
    800037fa:	08050913          	addi	s2,a0,128
    800037fe:	a021                	j	80003806 <itrunc+0x22>
    80003800:	0491                	addi	s1,s1,4
    80003802:	01248d63          	beq	s1,s2,8000381c <itrunc+0x38>
    if(ip->addrs[i]){
    80003806:	408c                	lw	a1,0(s1)
    80003808:	dde5                	beqz	a1,80003800 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000380a:	0009a503          	lw	a0,0(s3)
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	90c080e7          	jalr	-1780(ra) # 8000311a <bfree>
      ip->addrs[i] = 0;
    80003816:	0004a023          	sw	zero,0(s1)
    8000381a:	b7dd                	j	80003800 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000381c:	0809a583          	lw	a1,128(s3)
    80003820:	e185                	bnez	a1,80003840 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003822:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003826:	854e                	mv	a0,s3
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	de2080e7          	jalr	-542(ra) # 8000360a <iupdate>
}
    80003830:	70a2                	ld	ra,40(sp)
    80003832:	7402                	ld	s0,32(sp)
    80003834:	64e2                	ld	s1,24(sp)
    80003836:	6942                	ld	s2,16(sp)
    80003838:	69a2                	ld	s3,8(sp)
    8000383a:	6a02                	ld	s4,0(sp)
    8000383c:	6145                	addi	sp,sp,48
    8000383e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003840:	0009a503          	lw	a0,0(s3)
    80003844:	fffff097          	auipc	ra,0xfffff
    80003848:	690080e7          	jalr	1680(ra) # 80002ed4 <bread>
    8000384c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000384e:	05850493          	addi	s1,a0,88
    80003852:	45850913          	addi	s2,a0,1112
    80003856:	a021                	j	8000385e <itrunc+0x7a>
    80003858:	0491                	addi	s1,s1,4
    8000385a:	01248b63          	beq	s1,s2,80003870 <itrunc+0x8c>
      if(a[j])
    8000385e:	408c                	lw	a1,0(s1)
    80003860:	dde5                	beqz	a1,80003858 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003862:	0009a503          	lw	a0,0(s3)
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	8b4080e7          	jalr	-1868(ra) # 8000311a <bfree>
    8000386e:	b7ed                	j	80003858 <itrunc+0x74>
    brelse(bp);
    80003870:	8552                	mv	a0,s4
    80003872:	fffff097          	auipc	ra,0xfffff
    80003876:	792080e7          	jalr	1938(ra) # 80003004 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000387a:	0809a583          	lw	a1,128(s3)
    8000387e:	0009a503          	lw	a0,0(s3)
    80003882:	00000097          	auipc	ra,0x0
    80003886:	898080e7          	jalr	-1896(ra) # 8000311a <bfree>
    ip->addrs[NDIRECT] = 0;
    8000388a:	0809a023          	sw	zero,128(s3)
    8000388e:	bf51                	j	80003822 <itrunc+0x3e>

0000000080003890 <iput>:
{
    80003890:	1101                	addi	sp,sp,-32
    80003892:	ec06                	sd	ra,24(sp)
    80003894:	e822                	sd	s0,16(sp)
    80003896:	e426                	sd	s1,8(sp)
    80003898:	e04a                	sd	s2,0(sp)
    8000389a:	1000                	addi	s0,sp,32
    8000389c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000389e:	0001c517          	auipc	a0,0x1c
    800038a2:	12a50513          	addi	a0,a0,298 # 8001f9c8 <itable>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	32a080e7          	jalr	810(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038ae:	4498                	lw	a4,8(s1)
    800038b0:	4785                	li	a5,1
    800038b2:	02f70363          	beq	a4,a5,800038d8 <iput+0x48>
  ip->ref--;
    800038b6:	449c                	lw	a5,8(s1)
    800038b8:	37fd                	addiw	a5,a5,-1
    800038ba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038bc:	0001c517          	auipc	a0,0x1c
    800038c0:	10c50513          	addi	a0,a0,268 # 8001f9c8 <itable>
    800038c4:	ffffd097          	auipc	ra,0xffffd
    800038c8:	3c0080e7          	jalr	960(ra) # 80000c84 <release>
}
    800038cc:	60e2                	ld	ra,24(sp)
    800038ce:	6442                	ld	s0,16(sp)
    800038d0:	64a2                	ld	s1,8(sp)
    800038d2:	6902                	ld	s2,0(sp)
    800038d4:	6105                	addi	sp,sp,32
    800038d6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038d8:	40bc                	lw	a5,64(s1)
    800038da:	dff1                	beqz	a5,800038b6 <iput+0x26>
    800038dc:	04a49783          	lh	a5,74(s1)
    800038e0:	fbf9                	bnez	a5,800038b6 <iput+0x26>
    acquiresleep(&ip->lock);
    800038e2:	01048913          	addi	s2,s1,16
    800038e6:	854a                	mv	a0,s2
    800038e8:	00001097          	auipc	ra,0x1
    800038ec:	abe080e7          	jalr	-1346(ra) # 800043a6 <acquiresleep>
    release(&itable.lock);
    800038f0:	0001c517          	auipc	a0,0x1c
    800038f4:	0d850513          	addi	a0,a0,216 # 8001f9c8 <itable>
    800038f8:	ffffd097          	auipc	ra,0xffffd
    800038fc:	38c080e7          	jalr	908(ra) # 80000c84 <release>
    itrunc(ip);
    80003900:	8526                	mv	a0,s1
    80003902:	00000097          	auipc	ra,0x0
    80003906:	ee2080e7          	jalr	-286(ra) # 800037e4 <itrunc>
    ip->type = 0;
    8000390a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000390e:	8526                	mv	a0,s1
    80003910:	00000097          	auipc	ra,0x0
    80003914:	cfa080e7          	jalr	-774(ra) # 8000360a <iupdate>
    ip->valid = 0;
    80003918:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000391c:	854a                	mv	a0,s2
    8000391e:	00001097          	auipc	ra,0x1
    80003922:	ade080e7          	jalr	-1314(ra) # 800043fc <releasesleep>
    acquire(&itable.lock);
    80003926:	0001c517          	auipc	a0,0x1c
    8000392a:	0a250513          	addi	a0,a0,162 # 8001f9c8 <itable>
    8000392e:	ffffd097          	auipc	ra,0xffffd
    80003932:	2a2080e7          	jalr	674(ra) # 80000bd0 <acquire>
    80003936:	b741                	j	800038b6 <iput+0x26>

0000000080003938 <iunlockput>:
{
    80003938:	1101                	addi	sp,sp,-32
    8000393a:	ec06                	sd	ra,24(sp)
    8000393c:	e822                	sd	s0,16(sp)
    8000393e:	e426                	sd	s1,8(sp)
    80003940:	1000                	addi	s0,sp,32
    80003942:	84aa                	mv	s1,a0
  iunlock(ip);
    80003944:	00000097          	auipc	ra,0x0
    80003948:	e54080e7          	jalr	-428(ra) # 80003798 <iunlock>
  iput(ip);
    8000394c:	8526                	mv	a0,s1
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	f42080e7          	jalr	-190(ra) # 80003890 <iput>
}
    80003956:	60e2                	ld	ra,24(sp)
    80003958:	6442                	ld	s0,16(sp)
    8000395a:	64a2                	ld	s1,8(sp)
    8000395c:	6105                	addi	sp,sp,32
    8000395e:	8082                	ret

0000000080003960 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003960:	1141                	addi	sp,sp,-16
    80003962:	e422                	sd	s0,8(sp)
    80003964:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003966:	411c                	lw	a5,0(a0)
    80003968:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000396a:	415c                	lw	a5,4(a0)
    8000396c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000396e:	04451783          	lh	a5,68(a0)
    80003972:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003976:	04a51783          	lh	a5,74(a0)
    8000397a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000397e:	04c56783          	lwu	a5,76(a0)
    80003982:	e99c                	sd	a5,16(a1)
}
    80003984:	6422                	ld	s0,8(sp)
    80003986:	0141                	addi	sp,sp,16
    80003988:	8082                	ret

000000008000398a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000398a:	457c                	lw	a5,76(a0)
    8000398c:	0ed7e963          	bltu	a5,a3,80003a7e <readi+0xf4>
{
    80003990:	7159                	addi	sp,sp,-112
    80003992:	f486                	sd	ra,104(sp)
    80003994:	f0a2                	sd	s0,96(sp)
    80003996:	eca6                	sd	s1,88(sp)
    80003998:	e8ca                	sd	s2,80(sp)
    8000399a:	e4ce                	sd	s3,72(sp)
    8000399c:	e0d2                	sd	s4,64(sp)
    8000399e:	fc56                	sd	s5,56(sp)
    800039a0:	f85a                	sd	s6,48(sp)
    800039a2:	f45e                	sd	s7,40(sp)
    800039a4:	f062                	sd	s8,32(sp)
    800039a6:	ec66                	sd	s9,24(sp)
    800039a8:	e86a                	sd	s10,16(sp)
    800039aa:	e46e                	sd	s11,8(sp)
    800039ac:	1880                	addi	s0,sp,112
    800039ae:	8baa                	mv	s7,a0
    800039b0:	8c2e                	mv	s8,a1
    800039b2:	8ab2                	mv	s5,a2
    800039b4:	84b6                	mv	s1,a3
    800039b6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039b8:	9f35                	addw	a4,a4,a3
    return 0;
    800039ba:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039bc:	0ad76063          	bltu	a4,a3,80003a5c <readi+0xd2>
  if(off + n > ip->size)
    800039c0:	00e7f463          	bgeu	a5,a4,800039c8 <readi+0x3e>
    n = ip->size - off;
    800039c4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039c8:	0a0b0963          	beqz	s6,80003a7a <readi+0xf0>
    800039cc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039ce:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039d2:	5cfd                	li	s9,-1
    800039d4:	a82d                	j	80003a0e <readi+0x84>
    800039d6:	020a1d93          	slli	s11,s4,0x20
    800039da:	020ddd93          	srli	s11,s11,0x20
    800039de:	05890613          	addi	a2,s2,88
    800039e2:	86ee                	mv	a3,s11
    800039e4:	963a                	add	a2,a2,a4
    800039e6:	85d6                	mv	a1,s5
    800039e8:	8562                	mv	a0,s8
    800039ea:	fffff097          	auipc	ra,0xfffff
    800039ee:	aba080e7          	jalr	-1350(ra) # 800024a4 <either_copyout>
    800039f2:	05950d63          	beq	a0,s9,80003a4c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039f6:	854a                	mv	a0,s2
    800039f8:	fffff097          	auipc	ra,0xfffff
    800039fc:	60c080e7          	jalr	1548(ra) # 80003004 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a00:	013a09bb          	addw	s3,s4,s3
    80003a04:	009a04bb          	addw	s1,s4,s1
    80003a08:	9aee                	add	s5,s5,s11
    80003a0a:	0569f763          	bgeu	s3,s6,80003a58 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a0e:	000ba903          	lw	s2,0(s7)
    80003a12:	00a4d59b          	srliw	a1,s1,0xa
    80003a16:	855e                	mv	a0,s7
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	8ac080e7          	jalr	-1876(ra) # 800032c4 <bmap>
    80003a20:	0005059b          	sext.w	a1,a0
    80003a24:	854a                	mv	a0,s2
    80003a26:	fffff097          	auipc	ra,0xfffff
    80003a2a:	4ae080e7          	jalr	1198(ra) # 80002ed4 <bread>
    80003a2e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a30:	3ff4f713          	andi	a4,s1,1023
    80003a34:	40ed07bb          	subw	a5,s10,a4
    80003a38:	413b06bb          	subw	a3,s6,s3
    80003a3c:	8a3e                	mv	s4,a5
    80003a3e:	2781                	sext.w	a5,a5
    80003a40:	0006861b          	sext.w	a2,a3
    80003a44:	f8f679e3          	bgeu	a2,a5,800039d6 <readi+0x4c>
    80003a48:	8a36                	mv	s4,a3
    80003a4a:	b771                	j	800039d6 <readi+0x4c>
      brelse(bp);
    80003a4c:	854a                	mv	a0,s2
    80003a4e:	fffff097          	auipc	ra,0xfffff
    80003a52:	5b6080e7          	jalr	1462(ra) # 80003004 <brelse>
      tot = -1;
    80003a56:	59fd                	li	s3,-1
  }
  return tot;
    80003a58:	0009851b          	sext.w	a0,s3
}
    80003a5c:	70a6                	ld	ra,104(sp)
    80003a5e:	7406                	ld	s0,96(sp)
    80003a60:	64e6                	ld	s1,88(sp)
    80003a62:	6946                	ld	s2,80(sp)
    80003a64:	69a6                	ld	s3,72(sp)
    80003a66:	6a06                	ld	s4,64(sp)
    80003a68:	7ae2                	ld	s5,56(sp)
    80003a6a:	7b42                	ld	s6,48(sp)
    80003a6c:	7ba2                	ld	s7,40(sp)
    80003a6e:	7c02                	ld	s8,32(sp)
    80003a70:	6ce2                	ld	s9,24(sp)
    80003a72:	6d42                	ld	s10,16(sp)
    80003a74:	6da2                	ld	s11,8(sp)
    80003a76:	6165                	addi	sp,sp,112
    80003a78:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a7a:	89da                	mv	s3,s6
    80003a7c:	bff1                	j	80003a58 <readi+0xce>
    return 0;
    80003a7e:	4501                	li	a0,0
}
    80003a80:	8082                	ret

0000000080003a82 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a82:	457c                	lw	a5,76(a0)
    80003a84:	10d7e863          	bltu	a5,a3,80003b94 <writei+0x112>
{
    80003a88:	7159                	addi	sp,sp,-112
    80003a8a:	f486                	sd	ra,104(sp)
    80003a8c:	f0a2                	sd	s0,96(sp)
    80003a8e:	eca6                	sd	s1,88(sp)
    80003a90:	e8ca                	sd	s2,80(sp)
    80003a92:	e4ce                	sd	s3,72(sp)
    80003a94:	e0d2                	sd	s4,64(sp)
    80003a96:	fc56                	sd	s5,56(sp)
    80003a98:	f85a                	sd	s6,48(sp)
    80003a9a:	f45e                	sd	s7,40(sp)
    80003a9c:	f062                	sd	s8,32(sp)
    80003a9e:	ec66                	sd	s9,24(sp)
    80003aa0:	e86a                	sd	s10,16(sp)
    80003aa2:	e46e                	sd	s11,8(sp)
    80003aa4:	1880                	addi	s0,sp,112
    80003aa6:	8b2a                	mv	s6,a0
    80003aa8:	8c2e                	mv	s8,a1
    80003aaa:	8ab2                	mv	s5,a2
    80003aac:	8936                	mv	s2,a3
    80003aae:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ab0:	00e687bb          	addw	a5,a3,a4
    80003ab4:	0ed7e263          	bltu	a5,a3,80003b98 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ab8:	00043737          	lui	a4,0x43
    80003abc:	0ef76063          	bltu	a4,a5,80003b9c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ac0:	0c0b8863          	beqz	s7,80003b90 <writei+0x10e>
    80003ac4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003aca:	5cfd                	li	s9,-1
    80003acc:	a091                	j	80003b10 <writei+0x8e>
    80003ace:	02099d93          	slli	s11,s3,0x20
    80003ad2:	020ddd93          	srli	s11,s11,0x20
    80003ad6:	05848513          	addi	a0,s1,88
    80003ada:	86ee                	mv	a3,s11
    80003adc:	8656                	mv	a2,s5
    80003ade:	85e2                	mv	a1,s8
    80003ae0:	953a                	add	a0,a0,a4
    80003ae2:	fffff097          	auipc	ra,0xfffff
    80003ae6:	a18080e7          	jalr	-1512(ra) # 800024fa <either_copyin>
    80003aea:	07950263          	beq	a0,s9,80003b4e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003aee:	8526                	mv	a0,s1
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	798080e7          	jalr	1944(ra) # 80004288 <log_write>
    brelse(bp);
    80003af8:	8526                	mv	a0,s1
    80003afa:	fffff097          	auipc	ra,0xfffff
    80003afe:	50a080e7          	jalr	1290(ra) # 80003004 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b02:	01498a3b          	addw	s4,s3,s4
    80003b06:	0129893b          	addw	s2,s3,s2
    80003b0a:	9aee                	add	s5,s5,s11
    80003b0c:	057a7663          	bgeu	s4,s7,80003b58 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b10:	000b2483          	lw	s1,0(s6)
    80003b14:	00a9559b          	srliw	a1,s2,0xa
    80003b18:	855a                	mv	a0,s6
    80003b1a:	fffff097          	auipc	ra,0xfffff
    80003b1e:	7aa080e7          	jalr	1962(ra) # 800032c4 <bmap>
    80003b22:	0005059b          	sext.w	a1,a0
    80003b26:	8526                	mv	a0,s1
    80003b28:	fffff097          	auipc	ra,0xfffff
    80003b2c:	3ac080e7          	jalr	940(ra) # 80002ed4 <bread>
    80003b30:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b32:	3ff97713          	andi	a4,s2,1023
    80003b36:	40ed07bb          	subw	a5,s10,a4
    80003b3a:	414b86bb          	subw	a3,s7,s4
    80003b3e:	89be                	mv	s3,a5
    80003b40:	2781                	sext.w	a5,a5
    80003b42:	0006861b          	sext.w	a2,a3
    80003b46:	f8f674e3          	bgeu	a2,a5,80003ace <writei+0x4c>
    80003b4a:	89b6                	mv	s3,a3
    80003b4c:	b749                	j	80003ace <writei+0x4c>
      brelse(bp);
    80003b4e:	8526                	mv	a0,s1
    80003b50:	fffff097          	auipc	ra,0xfffff
    80003b54:	4b4080e7          	jalr	1204(ra) # 80003004 <brelse>
  }

  if(off > ip->size)
    80003b58:	04cb2783          	lw	a5,76(s6)
    80003b5c:	0127f463          	bgeu	a5,s2,80003b64 <writei+0xe2>
    ip->size = off;
    80003b60:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b64:	855a                	mv	a0,s6
    80003b66:	00000097          	auipc	ra,0x0
    80003b6a:	aa4080e7          	jalr	-1372(ra) # 8000360a <iupdate>

  return tot;
    80003b6e:	000a051b          	sext.w	a0,s4
}
    80003b72:	70a6                	ld	ra,104(sp)
    80003b74:	7406                	ld	s0,96(sp)
    80003b76:	64e6                	ld	s1,88(sp)
    80003b78:	6946                	ld	s2,80(sp)
    80003b7a:	69a6                	ld	s3,72(sp)
    80003b7c:	6a06                	ld	s4,64(sp)
    80003b7e:	7ae2                	ld	s5,56(sp)
    80003b80:	7b42                	ld	s6,48(sp)
    80003b82:	7ba2                	ld	s7,40(sp)
    80003b84:	7c02                	ld	s8,32(sp)
    80003b86:	6ce2                	ld	s9,24(sp)
    80003b88:	6d42                	ld	s10,16(sp)
    80003b8a:	6da2                	ld	s11,8(sp)
    80003b8c:	6165                	addi	sp,sp,112
    80003b8e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b90:	8a5e                	mv	s4,s7
    80003b92:	bfc9                	j	80003b64 <writei+0xe2>
    return -1;
    80003b94:	557d                	li	a0,-1
}
    80003b96:	8082                	ret
    return -1;
    80003b98:	557d                	li	a0,-1
    80003b9a:	bfe1                	j	80003b72 <writei+0xf0>
    return -1;
    80003b9c:	557d                	li	a0,-1
    80003b9e:	bfd1                	j	80003b72 <writei+0xf0>

0000000080003ba0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ba0:	1141                	addi	sp,sp,-16
    80003ba2:	e406                	sd	ra,8(sp)
    80003ba4:	e022                	sd	s0,0(sp)
    80003ba6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ba8:	4639                	li	a2,14
    80003baa:	ffffd097          	auipc	ra,0xffffd
    80003bae:	1f2080e7          	jalr	498(ra) # 80000d9c <strncmp>
}
    80003bb2:	60a2                	ld	ra,8(sp)
    80003bb4:	6402                	ld	s0,0(sp)
    80003bb6:	0141                	addi	sp,sp,16
    80003bb8:	8082                	ret

0000000080003bba <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bba:	7139                	addi	sp,sp,-64
    80003bbc:	fc06                	sd	ra,56(sp)
    80003bbe:	f822                	sd	s0,48(sp)
    80003bc0:	f426                	sd	s1,40(sp)
    80003bc2:	f04a                	sd	s2,32(sp)
    80003bc4:	ec4e                	sd	s3,24(sp)
    80003bc6:	e852                	sd	s4,16(sp)
    80003bc8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bca:	04451703          	lh	a4,68(a0)
    80003bce:	4785                	li	a5,1
    80003bd0:	00f71a63          	bne	a4,a5,80003be4 <dirlookup+0x2a>
    80003bd4:	892a                	mv	s2,a0
    80003bd6:	89ae                	mv	s3,a1
    80003bd8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bda:	457c                	lw	a5,76(a0)
    80003bdc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bde:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003be0:	e79d                	bnez	a5,80003c0e <dirlookup+0x54>
    80003be2:	a8a5                	j	80003c5a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003be4:	00005517          	auipc	a0,0x5
    80003be8:	aa450513          	addi	a0,a0,-1372 # 80008688 <syscalls+0x1c0>
    80003bec:	ffffd097          	auipc	ra,0xffffd
    80003bf0:	94e080e7          	jalr	-1714(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003bf4:	00005517          	auipc	a0,0x5
    80003bf8:	aac50513          	addi	a0,a0,-1364 # 800086a0 <syscalls+0x1d8>
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	93e080e7          	jalr	-1730(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c04:	24c1                	addiw	s1,s1,16
    80003c06:	04c92783          	lw	a5,76(s2)
    80003c0a:	04f4f763          	bgeu	s1,a5,80003c58 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c0e:	4741                	li	a4,16
    80003c10:	86a6                	mv	a3,s1
    80003c12:	fc040613          	addi	a2,s0,-64
    80003c16:	4581                	li	a1,0
    80003c18:	854a                	mv	a0,s2
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	d70080e7          	jalr	-656(ra) # 8000398a <readi>
    80003c22:	47c1                	li	a5,16
    80003c24:	fcf518e3          	bne	a0,a5,80003bf4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c28:	fc045783          	lhu	a5,-64(s0)
    80003c2c:	dfe1                	beqz	a5,80003c04 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c2e:	fc240593          	addi	a1,s0,-62
    80003c32:	854e                	mv	a0,s3
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	f6c080e7          	jalr	-148(ra) # 80003ba0 <namecmp>
    80003c3c:	f561                	bnez	a0,80003c04 <dirlookup+0x4a>
      if(poff)
    80003c3e:	000a0463          	beqz	s4,80003c46 <dirlookup+0x8c>
        *poff = off;
    80003c42:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c46:	fc045583          	lhu	a1,-64(s0)
    80003c4a:	00092503          	lw	a0,0(s2)
    80003c4e:	fffff097          	auipc	ra,0xfffff
    80003c52:	752080e7          	jalr	1874(ra) # 800033a0 <iget>
    80003c56:	a011                	j	80003c5a <dirlookup+0xa0>
  return 0;
    80003c58:	4501                	li	a0,0
}
    80003c5a:	70e2                	ld	ra,56(sp)
    80003c5c:	7442                	ld	s0,48(sp)
    80003c5e:	74a2                	ld	s1,40(sp)
    80003c60:	7902                	ld	s2,32(sp)
    80003c62:	69e2                	ld	s3,24(sp)
    80003c64:	6a42                	ld	s4,16(sp)
    80003c66:	6121                	addi	sp,sp,64
    80003c68:	8082                	ret

0000000080003c6a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c6a:	711d                	addi	sp,sp,-96
    80003c6c:	ec86                	sd	ra,88(sp)
    80003c6e:	e8a2                	sd	s0,80(sp)
    80003c70:	e4a6                	sd	s1,72(sp)
    80003c72:	e0ca                	sd	s2,64(sp)
    80003c74:	fc4e                	sd	s3,56(sp)
    80003c76:	f852                	sd	s4,48(sp)
    80003c78:	f456                	sd	s5,40(sp)
    80003c7a:	f05a                	sd	s6,32(sp)
    80003c7c:	ec5e                	sd	s7,24(sp)
    80003c7e:	e862                	sd	s8,16(sp)
    80003c80:	e466                	sd	s9,8(sp)
    80003c82:	e06a                	sd	s10,0(sp)
    80003c84:	1080                	addi	s0,sp,96
    80003c86:	84aa                	mv	s1,a0
    80003c88:	8b2e                	mv	s6,a1
    80003c8a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c8c:	00054703          	lbu	a4,0(a0)
    80003c90:	02f00793          	li	a5,47
    80003c94:	02f70363          	beq	a4,a5,80003cba <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c98:	ffffe097          	auipc	ra,0xffffe
    80003c9c:	d74080e7          	jalr	-652(ra) # 80001a0c <myproc>
    80003ca0:	15053503          	ld	a0,336(a0)
    80003ca4:	00000097          	auipc	ra,0x0
    80003ca8:	9f4080e7          	jalr	-1548(ra) # 80003698 <idup>
    80003cac:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003cae:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003cb2:	4cb5                	li	s9,13
  len = path - s;
    80003cb4:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cb6:	4c05                	li	s8,1
    80003cb8:	a87d                	j	80003d76 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003cba:	4585                	li	a1,1
    80003cbc:	4505                	li	a0,1
    80003cbe:	fffff097          	auipc	ra,0xfffff
    80003cc2:	6e2080e7          	jalr	1762(ra) # 800033a0 <iget>
    80003cc6:	8a2a                	mv	s4,a0
    80003cc8:	b7dd                	j	80003cae <namex+0x44>
      iunlockput(ip);
    80003cca:	8552                	mv	a0,s4
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	c6c080e7          	jalr	-916(ra) # 80003938 <iunlockput>
      return 0;
    80003cd4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cd6:	8552                	mv	a0,s4
    80003cd8:	60e6                	ld	ra,88(sp)
    80003cda:	6446                	ld	s0,80(sp)
    80003cdc:	64a6                	ld	s1,72(sp)
    80003cde:	6906                	ld	s2,64(sp)
    80003ce0:	79e2                	ld	s3,56(sp)
    80003ce2:	7a42                	ld	s4,48(sp)
    80003ce4:	7aa2                	ld	s5,40(sp)
    80003ce6:	7b02                	ld	s6,32(sp)
    80003ce8:	6be2                	ld	s7,24(sp)
    80003cea:	6c42                	ld	s8,16(sp)
    80003cec:	6ca2                	ld	s9,8(sp)
    80003cee:	6d02                	ld	s10,0(sp)
    80003cf0:	6125                	addi	sp,sp,96
    80003cf2:	8082                	ret
      iunlock(ip);
    80003cf4:	8552                	mv	a0,s4
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	aa2080e7          	jalr	-1374(ra) # 80003798 <iunlock>
      return ip;
    80003cfe:	bfe1                	j	80003cd6 <namex+0x6c>
      iunlockput(ip);
    80003d00:	8552                	mv	a0,s4
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	c36080e7          	jalr	-970(ra) # 80003938 <iunlockput>
      return 0;
    80003d0a:	8a4e                	mv	s4,s3
    80003d0c:	b7e9                	j	80003cd6 <namex+0x6c>
  len = path - s;
    80003d0e:	40998633          	sub	a2,s3,s1
    80003d12:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003d16:	09acd863          	bge	s9,s10,80003da6 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003d1a:	4639                	li	a2,14
    80003d1c:	85a6                	mv	a1,s1
    80003d1e:	8556                	mv	a0,s5
    80003d20:	ffffd097          	auipc	ra,0xffffd
    80003d24:	008080e7          	jalr	8(ra) # 80000d28 <memmove>
    80003d28:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d2a:	0004c783          	lbu	a5,0(s1)
    80003d2e:	01279763          	bne	a5,s2,80003d3c <namex+0xd2>
    path++;
    80003d32:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d34:	0004c783          	lbu	a5,0(s1)
    80003d38:	ff278de3          	beq	a5,s2,80003d32 <namex+0xc8>
    ilock(ip);
    80003d3c:	8552                	mv	a0,s4
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	998080e7          	jalr	-1640(ra) # 800036d6 <ilock>
    if(ip->type != T_DIR){
    80003d46:	044a1783          	lh	a5,68(s4)
    80003d4a:	f98790e3          	bne	a5,s8,80003cca <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003d4e:	000b0563          	beqz	s6,80003d58 <namex+0xee>
    80003d52:	0004c783          	lbu	a5,0(s1)
    80003d56:	dfd9                	beqz	a5,80003cf4 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d58:	865e                	mv	a2,s7
    80003d5a:	85d6                	mv	a1,s5
    80003d5c:	8552                	mv	a0,s4
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	e5c080e7          	jalr	-420(ra) # 80003bba <dirlookup>
    80003d66:	89aa                	mv	s3,a0
    80003d68:	dd41                	beqz	a0,80003d00 <namex+0x96>
    iunlockput(ip);
    80003d6a:	8552                	mv	a0,s4
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	bcc080e7          	jalr	-1076(ra) # 80003938 <iunlockput>
    ip = next;
    80003d74:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003d76:	0004c783          	lbu	a5,0(s1)
    80003d7a:	01279763          	bne	a5,s2,80003d88 <namex+0x11e>
    path++;
    80003d7e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d80:	0004c783          	lbu	a5,0(s1)
    80003d84:	ff278de3          	beq	a5,s2,80003d7e <namex+0x114>
  if(*path == 0)
    80003d88:	cb9d                	beqz	a5,80003dbe <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d8a:	0004c783          	lbu	a5,0(s1)
    80003d8e:	89a6                	mv	s3,s1
  len = path - s;
    80003d90:	8d5e                	mv	s10,s7
    80003d92:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d94:	01278963          	beq	a5,s2,80003da6 <namex+0x13c>
    80003d98:	dbbd                	beqz	a5,80003d0e <namex+0xa4>
    path++;
    80003d9a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d9c:	0009c783          	lbu	a5,0(s3)
    80003da0:	ff279ce3          	bne	a5,s2,80003d98 <namex+0x12e>
    80003da4:	b7ad                	j	80003d0e <namex+0xa4>
    memmove(name, s, len);
    80003da6:	2601                	sext.w	a2,a2
    80003da8:	85a6                	mv	a1,s1
    80003daa:	8556                	mv	a0,s5
    80003dac:	ffffd097          	auipc	ra,0xffffd
    80003db0:	f7c080e7          	jalr	-132(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003db4:	9d56                	add	s10,s10,s5
    80003db6:	000d0023          	sb	zero,0(s10)
    80003dba:	84ce                	mv	s1,s3
    80003dbc:	b7bd                	j	80003d2a <namex+0xc0>
  if(nameiparent){
    80003dbe:	f00b0ce3          	beqz	s6,80003cd6 <namex+0x6c>
    iput(ip);
    80003dc2:	8552                	mv	a0,s4
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	acc080e7          	jalr	-1332(ra) # 80003890 <iput>
    return 0;
    80003dcc:	4a01                	li	s4,0
    80003dce:	b721                	j	80003cd6 <namex+0x6c>

0000000080003dd0 <dirlink>:
{
    80003dd0:	7139                	addi	sp,sp,-64
    80003dd2:	fc06                	sd	ra,56(sp)
    80003dd4:	f822                	sd	s0,48(sp)
    80003dd6:	f426                	sd	s1,40(sp)
    80003dd8:	f04a                	sd	s2,32(sp)
    80003dda:	ec4e                	sd	s3,24(sp)
    80003ddc:	e852                	sd	s4,16(sp)
    80003dde:	0080                	addi	s0,sp,64
    80003de0:	892a                	mv	s2,a0
    80003de2:	8a2e                	mv	s4,a1
    80003de4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003de6:	4601                	li	a2,0
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	dd2080e7          	jalr	-558(ra) # 80003bba <dirlookup>
    80003df0:	e93d                	bnez	a0,80003e66 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df2:	04c92483          	lw	s1,76(s2)
    80003df6:	c49d                	beqz	s1,80003e24 <dirlink+0x54>
    80003df8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dfa:	4741                	li	a4,16
    80003dfc:	86a6                	mv	a3,s1
    80003dfe:	fc040613          	addi	a2,s0,-64
    80003e02:	4581                	li	a1,0
    80003e04:	854a                	mv	a0,s2
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	b84080e7          	jalr	-1148(ra) # 8000398a <readi>
    80003e0e:	47c1                	li	a5,16
    80003e10:	06f51163          	bne	a0,a5,80003e72 <dirlink+0xa2>
    if(de.inum == 0)
    80003e14:	fc045783          	lhu	a5,-64(s0)
    80003e18:	c791                	beqz	a5,80003e24 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e1a:	24c1                	addiw	s1,s1,16
    80003e1c:	04c92783          	lw	a5,76(s2)
    80003e20:	fcf4ede3          	bltu	s1,a5,80003dfa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e24:	4639                	li	a2,14
    80003e26:	85d2                	mv	a1,s4
    80003e28:	fc240513          	addi	a0,s0,-62
    80003e2c:	ffffd097          	auipc	ra,0xffffd
    80003e30:	fac080e7          	jalr	-84(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003e34:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e38:	4741                	li	a4,16
    80003e3a:	86a6                	mv	a3,s1
    80003e3c:	fc040613          	addi	a2,s0,-64
    80003e40:	4581                	li	a1,0
    80003e42:	854a                	mv	a0,s2
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	c3e080e7          	jalr	-962(ra) # 80003a82 <writei>
    80003e4c:	872a                	mv	a4,a0
    80003e4e:	47c1                	li	a5,16
  return 0;
    80003e50:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e52:	02f71863          	bne	a4,a5,80003e82 <dirlink+0xb2>
}
    80003e56:	70e2                	ld	ra,56(sp)
    80003e58:	7442                	ld	s0,48(sp)
    80003e5a:	74a2                	ld	s1,40(sp)
    80003e5c:	7902                	ld	s2,32(sp)
    80003e5e:	69e2                	ld	s3,24(sp)
    80003e60:	6a42                	ld	s4,16(sp)
    80003e62:	6121                	addi	sp,sp,64
    80003e64:	8082                	ret
    iput(ip);
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	a2a080e7          	jalr	-1494(ra) # 80003890 <iput>
    return -1;
    80003e6e:	557d                	li	a0,-1
    80003e70:	b7dd                	j	80003e56 <dirlink+0x86>
      panic("dirlink read");
    80003e72:	00005517          	auipc	a0,0x5
    80003e76:	83e50513          	addi	a0,a0,-1986 # 800086b0 <syscalls+0x1e8>
    80003e7a:	ffffc097          	auipc	ra,0xffffc
    80003e7e:	6c0080e7          	jalr	1728(ra) # 8000053a <panic>
    panic("dirlink");
    80003e82:	00005517          	auipc	a0,0x5
    80003e86:	93e50513          	addi	a0,a0,-1730 # 800087c0 <syscalls+0x2f8>
    80003e8a:	ffffc097          	auipc	ra,0xffffc
    80003e8e:	6b0080e7          	jalr	1712(ra) # 8000053a <panic>

0000000080003e92 <namei>:

struct inode*
namei(char *path)
{
    80003e92:	1101                	addi	sp,sp,-32
    80003e94:	ec06                	sd	ra,24(sp)
    80003e96:	e822                	sd	s0,16(sp)
    80003e98:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e9a:	fe040613          	addi	a2,s0,-32
    80003e9e:	4581                	li	a1,0
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	dca080e7          	jalr	-566(ra) # 80003c6a <namex>
}
    80003ea8:	60e2                	ld	ra,24(sp)
    80003eaa:	6442                	ld	s0,16(sp)
    80003eac:	6105                	addi	sp,sp,32
    80003eae:	8082                	ret

0000000080003eb0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003eb0:	1141                	addi	sp,sp,-16
    80003eb2:	e406                	sd	ra,8(sp)
    80003eb4:	e022                	sd	s0,0(sp)
    80003eb6:	0800                	addi	s0,sp,16
    80003eb8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003eba:	4585                	li	a1,1
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	dae080e7          	jalr	-594(ra) # 80003c6a <namex>
}
    80003ec4:	60a2                	ld	ra,8(sp)
    80003ec6:	6402                	ld	s0,0(sp)
    80003ec8:	0141                	addi	sp,sp,16
    80003eca:	8082                	ret

0000000080003ecc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ecc:	1101                	addi	sp,sp,-32
    80003ece:	ec06                	sd	ra,24(sp)
    80003ed0:	e822                	sd	s0,16(sp)
    80003ed2:	e426                	sd	s1,8(sp)
    80003ed4:	e04a                	sd	s2,0(sp)
    80003ed6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ed8:	0001d917          	auipc	s2,0x1d
    80003edc:	59890913          	addi	s2,s2,1432 # 80021470 <log>
    80003ee0:	01892583          	lw	a1,24(s2)
    80003ee4:	02892503          	lw	a0,40(s2)
    80003ee8:	fffff097          	auipc	ra,0xfffff
    80003eec:	fec080e7          	jalr	-20(ra) # 80002ed4 <bread>
    80003ef0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ef2:	02c92683          	lw	a3,44(s2)
    80003ef6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ef8:	02d05863          	blez	a3,80003f28 <write_head+0x5c>
    80003efc:	0001d797          	auipc	a5,0x1d
    80003f00:	5a478793          	addi	a5,a5,1444 # 800214a0 <log+0x30>
    80003f04:	05c50713          	addi	a4,a0,92
    80003f08:	36fd                	addiw	a3,a3,-1
    80003f0a:	02069613          	slli	a2,a3,0x20
    80003f0e:	01e65693          	srli	a3,a2,0x1e
    80003f12:	0001d617          	auipc	a2,0x1d
    80003f16:	59260613          	addi	a2,a2,1426 # 800214a4 <log+0x34>
    80003f1a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f1c:	4390                	lw	a2,0(a5)
    80003f1e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f20:	0791                	addi	a5,a5,4
    80003f22:	0711                	addi	a4,a4,4
    80003f24:	fed79ce3          	bne	a5,a3,80003f1c <write_head+0x50>
  }
  bwrite(buf);
    80003f28:	8526                	mv	a0,s1
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	09c080e7          	jalr	156(ra) # 80002fc6 <bwrite>
  brelse(buf);
    80003f32:	8526                	mv	a0,s1
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	0d0080e7          	jalr	208(ra) # 80003004 <brelse>
}
    80003f3c:	60e2                	ld	ra,24(sp)
    80003f3e:	6442                	ld	s0,16(sp)
    80003f40:	64a2                	ld	s1,8(sp)
    80003f42:	6902                	ld	s2,0(sp)
    80003f44:	6105                	addi	sp,sp,32
    80003f46:	8082                	ret

0000000080003f48 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f48:	0001d797          	auipc	a5,0x1d
    80003f4c:	5547a783          	lw	a5,1364(a5) # 8002149c <log+0x2c>
    80003f50:	0af05d63          	blez	a5,8000400a <install_trans+0xc2>
{
    80003f54:	7139                	addi	sp,sp,-64
    80003f56:	fc06                	sd	ra,56(sp)
    80003f58:	f822                	sd	s0,48(sp)
    80003f5a:	f426                	sd	s1,40(sp)
    80003f5c:	f04a                	sd	s2,32(sp)
    80003f5e:	ec4e                	sd	s3,24(sp)
    80003f60:	e852                	sd	s4,16(sp)
    80003f62:	e456                	sd	s5,8(sp)
    80003f64:	e05a                	sd	s6,0(sp)
    80003f66:	0080                	addi	s0,sp,64
    80003f68:	8b2a                	mv	s6,a0
    80003f6a:	0001da97          	auipc	s5,0x1d
    80003f6e:	536a8a93          	addi	s5,s5,1334 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f72:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f74:	0001d997          	auipc	s3,0x1d
    80003f78:	4fc98993          	addi	s3,s3,1276 # 80021470 <log>
    80003f7c:	a00d                	j	80003f9e <install_trans+0x56>
    brelse(lbuf);
    80003f7e:	854a                	mv	a0,s2
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	084080e7          	jalr	132(ra) # 80003004 <brelse>
    brelse(dbuf);
    80003f88:	8526                	mv	a0,s1
    80003f8a:	fffff097          	auipc	ra,0xfffff
    80003f8e:	07a080e7          	jalr	122(ra) # 80003004 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f92:	2a05                	addiw	s4,s4,1
    80003f94:	0a91                	addi	s5,s5,4
    80003f96:	02c9a783          	lw	a5,44(s3)
    80003f9a:	04fa5e63          	bge	s4,a5,80003ff6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f9e:	0189a583          	lw	a1,24(s3)
    80003fa2:	014585bb          	addw	a1,a1,s4
    80003fa6:	2585                	addiw	a1,a1,1
    80003fa8:	0289a503          	lw	a0,40(s3)
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	f28080e7          	jalr	-216(ra) # 80002ed4 <bread>
    80003fb4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fb6:	000aa583          	lw	a1,0(s5)
    80003fba:	0289a503          	lw	a0,40(s3)
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	f16080e7          	jalr	-234(ra) # 80002ed4 <bread>
    80003fc6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fc8:	40000613          	li	a2,1024
    80003fcc:	05890593          	addi	a1,s2,88
    80003fd0:	05850513          	addi	a0,a0,88
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	d54080e7          	jalr	-684(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fdc:	8526                	mv	a0,s1
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	fe8080e7          	jalr	-24(ra) # 80002fc6 <bwrite>
    if(recovering == 0)
    80003fe6:	f80b1ce3          	bnez	s6,80003f7e <install_trans+0x36>
      bunpin(dbuf);
    80003fea:	8526                	mv	a0,s1
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	0f2080e7          	jalr	242(ra) # 800030de <bunpin>
    80003ff4:	b769                	j	80003f7e <install_trans+0x36>
}
    80003ff6:	70e2                	ld	ra,56(sp)
    80003ff8:	7442                	ld	s0,48(sp)
    80003ffa:	74a2                	ld	s1,40(sp)
    80003ffc:	7902                	ld	s2,32(sp)
    80003ffe:	69e2                	ld	s3,24(sp)
    80004000:	6a42                	ld	s4,16(sp)
    80004002:	6aa2                	ld	s5,8(sp)
    80004004:	6b02                	ld	s6,0(sp)
    80004006:	6121                	addi	sp,sp,64
    80004008:	8082                	ret
    8000400a:	8082                	ret

000000008000400c <initlog>:
{
    8000400c:	7179                	addi	sp,sp,-48
    8000400e:	f406                	sd	ra,40(sp)
    80004010:	f022                	sd	s0,32(sp)
    80004012:	ec26                	sd	s1,24(sp)
    80004014:	e84a                	sd	s2,16(sp)
    80004016:	e44e                	sd	s3,8(sp)
    80004018:	1800                	addi	s0,sp,48
    8000401a:	892a                	mv	s2,a0
    8000401c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000401e:	0001d497          	auipc	s1,0x1d
    80004022:	45248493          	addi	s1,s1,1106 # 80021470 <log>
    80004026:	00004597          	auipc	a1,0x4
    8000402a:	69a58593          	addi	a1,a1,1690 # 800086c0 <syscalls+0x1f8>
    8000402e:	8526                	mv	a0,s1
    80004030:	ffffd097          	auipc	ra,0xffffd
    80004034:	b10080e7          	jalr	-1264(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80004038:	0149a583          	lw	a1,20(s3)
    8000403c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000403e:	0109a783          	lw	a5,16(s3)
    80004042:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004044:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004048:	854a                	mv	a0,s2
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	e8a080e7          	jalr	-374(ra) # 80002ed4 <bread>
  log.lh.n = lh->n;
    80004052:	4d34                	lw	a3,88(a0)
    80004054:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004056:	02d05663          	blez	a3,80004082 <initlog+0x76>
    8000405a:	05c50793          	addi	a5,a0,92
    8000405e:	0001d717          	auipc	a4,0x1d
    80004062:	44270713          	addi	a4,a4,1090 # 800214a0 <log+0x30>
    80004066:	36fd                	addiw	a3,a3,-1
    80004068:	02069613          	slli	a2,a3,0x20
    8000406c:	01e65693          	srli	a3,a2,0x1e
    80004070:	06050613          	addi	a2,a0,96
    80004074:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004076:	4390                	lw	a2,0(a5)
    80004078:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000407a:	0791                	addi	a5,a5,4
    8000407c:	0711                	addi	a4,a4,4
    8000407e:	fed79ce3          	bne	a5,a3,80004076 <initlog+0x6a>
  brelse(buf);
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	f82080e7          	jalr	-126(ra) # 80003004 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000408a:	4505                	li	a0,1
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	ebc080e7          	jalr	-324(ra) # 80003f48 <install_trans>
  log.lh.n = 0;
    80004094:	0001d797          	auipc	a5,0x1d
    80004098:	4007a423          	sw	zero,1032(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	e30080e7          	jalr	-464(ra) # 80003ecc <write_head>
}
    800040a4:	70a2                	ld	ra,40(sp)
    800040a6:	7402                	ld	s0,32(sp)
    800040a8:	64e2                	ld	s1,24(sp)
    800040aa:	6942                	ld	s2,16(sp)
    800040ac:	69a2                	ld	s3,8(sp)
    800040ae:	6145                	addi	sp,sp,48
    800040b0:	8082                	ret

00000000800040b2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040b2:	1101                	addi	sp,sp,-32
    800040b4:	ec06                	sd	ra,24(sp)
    800040b6:	e822                	sd	s0,16(sp)
    800040b8:	e426                	sd	s1,8(sp)
    800040ba:	e04a                	sd	s2,0(sp)
    800040bc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040be:	0001d517          	auipc	a0,0x1d
    800040c2:	3b250513          	addi	a0,a0,946 # 80021470 <log>
    800040c6:	ffffd097          	auipc	ra,0xffffd
    800040ca:	b0a080e7          	jalr	-1270(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    800040ce:	0001d497          	auipc	s1,0x1d
    800040d2:	3a248493          	addi	s1,s1,930 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040d6:	4979                	li	s2,30
    800040d8:	a039                	j	800040e6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040da:	85a6                	mv	a1,s1
    800040dc:	8526                	mv	a0,s1
    800040de:	ffffe097          	auipc	ra,0xffffe
    800040e2:	022080e7          	jalr	34(ra) # 80002100 <sleep>
    if(log.committing){
    800040e6:	50dc                	lw	a5,36(s1)
    800040e8:	fbed                	bnez	a5,800040da <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ea:	5098                	lw	a4,32(s1)
    800040ec:	2705                	addiw	a4,a4,1
    800040ee:	0007069b          	sext.w	a3,a4
    800040f2:	0027179b          	slliw	a5,a4,0x2
    800040f6:	9fb9                	addw	a5,a5,a4
    800040f8:	0017979b          	slliw	a5,a5,0x1
    800040fc:	54d8                	lw	a4,44(s1)
    800040fe:	9fb9                	addw	a5,a5,a4
    80004100:	00f95963          	bge	s2,a5,80004112 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004104:	85a6                	mv	a1,s1
    80004106:	8526                	mv	a0,s1
    80004108:	ffffe097          	auipc	ra,0xffffe
    8000410c:	ff8080e7          	jalr	-8(ra) # 80002100 <sleep>
    80004110:	bfd9                	j	800040e6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004112:	0001d517          	auipc	a0,0x1d
    80004116:	35e50513          	addi	a0,a0,862 # 80021470 <log>
    8000411a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000411c:	ffffd097          	auipc	ra,0xffffd
    80004120:	b68080e7          	jalr	-1176(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004124:	60e2                	ld	ra,24(sp)
    80004126:	6442                	ld	s0,16(sp)
    80004128:	64a2                	ld	s1,8(sp)
    8000412a:	6902                	ld	s2,0(sp)
    8000412c:	6105                	addi	sp,sp,32
    8000412e:	8082                	ret

0000000080004130 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004130:	7139                	addi	sp,sp,-64
    80004132:	fc06                	sd	ra,56(sp)
    80004134:	f822                	sd	s0,48(sp)
    80004136:	f426                	sd	s1,40(sp)
    80004138:	f04a                	sd	s2,32(sp)
    8000413a:	ec4e                	sd	s3,24(sp)
    8000413c:	e852                	sd	s4,16(sp)
    8000413e:	e456                	sd	s5,8(sp)
    80004140:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004142:	0001d497          	auipc	s1,0x1d
    80004146:	32e48493          	addi	s1,s1,814 # 80021470 <log>
    8000414a:	8526                	mv	a0,s1
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	a84080e7          	jalr	-1404(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    80004154:	509c                	lw	a5,32(s1)
    80004156:	37fd                	addiw	a5,a5,-1
    80004158:	0007891b          	sext.w	s2,a5
    8000415c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000415e:	50dc                	lw	a5,36(s1)
    80004160:	e7b9                	bnez	a5,800041ae <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004162:	04091e63          	bnez	s2,800041be <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004166:	0001d497          	auipc	s1,0x1d
    8000416a:	30a48493          	addi	s1,s1,778 # 80021470 <log>
    8000416e:	4785                	li	a5,1
    80004170:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004172:	8526                	mv	a0,s1
    80004174:	ffffd097          	auipc	ra,0xffffd
    80004178:	b10080e7          	jalr	-1264(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000417c:	54dc                	lw	a5,44(s1)
    8000417e:	06f04763          	bgtz	a5,800041ec <end_op+0xbc>
    acquire(&log.lock);
    80004182:	0001d497          	auipc	s1,0x1d
    80004186:	2ee48493          	addi	s1,s1,750 # 80021470 <log>
    8000418a:	8526                	mv	a0,s1
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	a44080e7          	jalr	-1468(ra) # 80000bd0 <acquire>
    log.committing = 0;
    80004194:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004198:	8526                	mv	a0,s1
    8000419a:	ffffe097          	auipc	ra,0xffffe
    8000419e:	0f2080e7          	jalr	242(ra) # 8000228c <wakeup>
    release(&log.lock);
    800041a2:	8526                	mv	a0,s1
    800041a4:	ffffd097          	auipc	ra,0xffffd
    800041a8:	ae0080e7          	jalr	-1312(ra) # 80000c84 <release>
}
    800041ac:	a03d                	j	800041da <end_op+0xaa>
    panic("log.committing");
    800041ae:	00004517          	auipc	a0,0x4
    800041b2:	51a50513          	addi	a0,a0,1306 # 800086c8 <syscalls+0x200>
    800041b6:	ffffc097          	auipc	ra,0xffffc
    800041ba:	384080e7          	jalr	900(ra) # 8000053a <panic>
    wakeup(&log);
    800041be:	0001d497          	auipc	s1,0x1d
    800041c2:	2b248493          	addi	s1,s1,690 # 80021470 <log>
    800041c6:	8526                	mv	a0,s1
    800041c8:	ffffe097          	auipc	ra,0xffffe
    800041cc:	0c4080e7          	jalr	196(ra) # 8000228c <wakeup>
  release(&log.lock);
    800041d0:	8526                	mv	a0,s1
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	ab2080e7          	jalr	-1358(ra) # 80000c84 <release>
}
    800041da:	70e2                	ld	ra,56(sp)
    800041dc:	7442                	ld	s0,48(sp)
    800041de:	74a2                	ld	s1,40(sp)
    800041e0:	7902                	ld	s2,32(sp)
    800041e2:	69e2                	ld	s3,24(sp)
    800041e4:	6a42                	ld	s4,16(sp)
    800041e6:	6aa2                	ld	s5,8(sp)
    800041e8:	6121                	addi	sp,sp,64
    800041ea:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ec:	0001da97          	auipc	s5,0x1d
    800041f0:	2b4a8a93          	addi	s5,s5,692 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041f4:	0001da17          	auipc	s4,0x1d
    800041f8:	27ca0a13          	addi	s4,s4,636 # 80021470 <log>
    800041fc:	018a2583          	lw	a1,24(s4)
    80004200:	012585bb          	addw	a1,a1,s2
    80004204:	2585                	addiw	a1,a1,1
    80004206:	028a2503          	lw	a0,40(s4)
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	cca080e7          	jalr	-822(ra) # 80002ed4 <bread>
    80004212:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004214:	000aa583          	lw	a1,0(s5)
    80004218:	028a2503          	lw	a0,40(s4)
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	cb8080e7          	jalr	-840(ra) # 80002ed4 <bread>
    80004224:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004226:	40000613          	li	a2,1024
    8000422a:	05850593          	addi	a1,a0,88
    8000422e:	05848513          	addi	a0,s1,88
    80004232:	ffffd097          	auipc	ra,0xffffd
    80004236:	af6080e7          	jalr	-1290(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000423a:	8526                	mv	a0,s1
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	d8a080e7          	jalr	-630(ra) # 80002fc6 <bwrite>
    brelse(from);
    80004244:	854e                	mv	a0,s3
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	dbe080e7          	jalr	-578(ra) # 80003004 <brelse>
    brelse(to);
    8000424e:	8526                	mv	a0,s1
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	db4080e7          	jalr	-588(ra) # 80003004 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004258:	2905                	addiw	s2,s2,1
    8000425a:	0a91                	addi	s5,s5,4
    8000425c:	02ca2783          	lw	a5,44(s4)
    80004260:	f8f94ee3          	blt	s2,a5,800041fc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004264:	00000097          	auipc	ra,0x0
    80004268:	c68080e7          	jalr	-920(ra) # 80003ecc <write_head>
    install_trans(0); // Now install writes to home locations
    8000426c:	4501                	li	a0,0
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	cda080e7          	jalr	-806(ra) # 80003f48 <install_trans>
    log.lh.n = 0;
    80004276:	0001d797          	auipc	a5,0x1d
    8000427a:	2207a323          	sw	zero,550(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	c4e080e7          	jalr	-946(ra) # 80003ecc <write_head>
    80004286:	bdf5                	j	80004182 <end_op+0x52>

0000000080004288 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004288:	1101                	addi	sp,sp,-32
    8000428a:	ec06                	sd	ra,24(sp)
    8000428c:	e822                	sd	s0,16(sp)
    8000428e:	e426                	sd	s1,8(sp)
    80004290:	e04a                	sd	s2,0(sp)
    80004292:	1000                	addi	s0,sp,32
    80004294:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004296:	0001d917          	auipc	s2,0x1d
    8000429a:	1da90913          	addi	s2,s2,474 # 80021470 <log>
    8000429e:	854a                	mv	a0,s2
    800042a0:	ffffd097          	auipc	ra,0xffffd
    800042a4:	930080e7          	jalr	-1744(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042a8:	02c92603          	lw	a2,44(s2)
    800042ac:	47f5                	li	a5,29
    800042ae:	06c7c563          	blt	a5,a2,80004318 <log_write+0x90>
    800042b2:	0001d797          	auipc	a5,0x1d
    800042b6:	1da7a783          	lw	a5,474(a5) # 8002148c <log+0x1c>
    800042ba:	37fd                	addiw	a5,a5,-1
    800042bc:	04f65e63          	bge	a2,a5,80004318 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042c0:	0001d797          	auipc	a5,0x1d
    800042c4:	1d07a783          	lw	a5,464(a5) # 80021490 <log+0x20>
    800042c8:	06f05063          	blez	a5,80004328 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042cc:	4781                	li	a5,0
    800042ce:	06c05563          	blez	a2,80004338 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042d2:	44cc                	lw	a1,12(s1)
    800042d4:	0001d717          	auipc	a4,0x1d
    800042d8:	1cc70713          	addi	a4,a4,460 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042dc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042de:	4314                	lw	a3,0(a4)
    800042e0:	04b68c63          	beq	a3,a1,80004338 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042e4:	2785                	addiw	a5,a5,1
    800042e6:	0711                	addi	a4,a4,4
    800042e8:	fef61be3          	bne	a2,a5,800042de <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042ec:	0621                	addi	a2,a2,8
    800042ee:	060a                	slli	a2,a2,0x2
    800042f0:	0001d797          	auipc	a5,0x1d
    800042f4:	18078793          	addi	a5,a5,384 # 80021470 <log>
    800042f8:	97b2                	add	a5,a5,a2
    800042fa:	44d8                	lw	a4,12(s1)
    800042fc:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042fe:	8526                	mv	a0,s1
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	da2080e7          	jalr	-606(ra) # 800030a2 <bpin>
    log.lh.n++;
    80004308:	0001d717          	auipc	a4,0x1d
    8000430c:	16870713          	addi	a4,a4,360 # 80021470 <log>
    80004310:	575c                	lw	a5,44(a4)
    80004312:	2785                	addiw	a5,a5,1
    80004314:	d75c                	sw	a5,44(a4)
    80004316:	a82d                	j	80004350 <log_write+0xc8>
    panic("too big a transaction");
    80004318:	00004517          	auipc	a0,0x4
    8000431c:	3c050513          	addi	a0,a0,960 # 800086d8 <syscalls+0x210>
    80004320:	ffffc097          	auipc	ra,0xffffc
    80004324:	21a080e7          	jalr	538(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	3c850513          	addi	a0,a0,968 # 800086f0 <syscalls+0x228>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	20a080e7          	jalr	522(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004338:	00878693          	addi	a3,a5,8
    8000433c:	068a                	slli	a3,a3,0x2
    8000433e:	0001d717          	auipc	a4,0x1d
    80004342:	13270713          	addi	a4,a4,306 # 80021470 <log>
    80004346:	9736                	add	a4,a4,a3
    80004348:	44d4                	lw	a3,12(s1)
    8000434a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000434c:	faf609e3          	beq	a2,a5,800042fe <log_write+0x76>
  }
  release(&log.lock);
    80004350:	0001d517          	auipc	a0,0x1d
    80004354:	12050513          	addi	a0,a0,288 # 80021470 <log>
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	92c080e7          	jalr	-1748(ra) # 80000c84 <release>
}
    80004360:	60e2                	ld	ra,24(sp)
    80004362:	6442                	ld	s0,16(sp)
    80004364:	64a2                	ld	s1,8(sp)
    80004366:	6902                	ld	s2,0(sp)
    80004368:	6105                	addi	sp,sp,32
    8000436a:	8082                	ret

000000008000436c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000436c:	1101                	addi	sp,sp,-32
    8000436e:	ec06                	sd	ra,24(sp)
    80004370:	e822                	sd	s0,16(sp)
    80004372:	e426                	sd	s1,8(sp)
    80004374:	e04a                	sd	s2,0(sp)
    80004376:	1000                	addi	s0,sp,32
    80004378:	84aa                	mv	s1,a0
    8000437a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000437c:	00004597          	auipc	a1,0x4
    80004380:	39458593          	addi	a1,a1,916 # 80008710 <syscalls+0x248>
    80004384:	0521                	addi	a0,a0,8
    80004386:	ffffc097          	auipc	ra,0xffffc
    8000438a:	7ba080e7          	jalr	1978(ra) # 80000b40 <initlock>
  lk->name = name;
    8000438e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004392:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004396:	0204a423          	sw	zero,40(s1)
}
    8000439a:	60e2                	ld	ra,24(sp)
    8000439c:	6442                	ld	s0,16(sp)
    8000439e:	64a2                	ld	s1,8(sp)
    800043a0:	6902                	ld	s2,0(sp)
    800043a2:	6105                	addi	sp,sp,32
    800043a4:	8082                	ret

00000000800043a6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043a6:	1101                	addi	sp,sp,-32
    800043a8:	ec06                	sd	ra,24(sp)
    800043aa:	e822                	sd	s0,16(sp)
    800043ac:	e426                	sd	s1,8(sp)
    800043ae:	e04a                	sd	s2,0(sp)
    800043b0:	1000                	addi	s0,sp,32
    800043b2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043b4:	00850913          	addi	s2,a0,8
    800043b8:	854a                	mv	a0,s2
    800043ba:	ffffd097          	auipc	ra,0xffffd
    800043be:	816080e7          	jalr	-2026(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800043c2:	409c                	lw	a5,0(s1)
    800043c4:	cb89                	beqz	a5,800043d6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043c6:	85ca                	mv	a1,s2
    800043c8:	8526                	mv	a0,s1
    800043ca:	ffffe097          	auipc	ra,0xffffe
    800043ce:	d36080e7          	jalr	-714(ra) # 80002100 <sleep>
  while (lk->locked) {
    800043d2:	409c                	lw	a5,0(s1)
    800043d4:	fbed                	bnez	a5,800043c6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043d6:	4785                	li	a5,1
    800043d8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	632080e7          	jalr	1586(ra) # 80001a0c <myproc>
    800043e2:	591c                	lw	a5,48(a0)
    800043e4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043e6:	854a                	mv	a0,s2
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	89c080e7          	jalr	-1892(ra) # 80000c84 <release>
}
    800043f0:	60e2                	ld	ra,24(sp)
    800043f2:	6442                	ld	s0,16(sp)
    800043f4:	64a2                	ld	s1,8(sp)
    800043f6:	6902                	ld	s2,0(sp)
    800043f8:	6105                	addi	sp,sp,32
    800043fa:	8082                	ret

00000000800043fc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043fc:	1101                	addi	sp,sp,-32
    800043fe:	ec06                	sd	ra,24(sp)
    80004400:	e822                	sd	s0,16(sp)
    80004402:	e426                	sd	s1,8(sp)
    80004404:	e04a                	sd	s2,0(sp)
    80004406:	1000                	addi	s0,sp,32
    80004408:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000440a:	00850913          	addi	s2,a0,8
    8000440e:	854a                	mv	a0,s2
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	7c0080e7          	jalr	1984(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004418:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000441c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004420:	8526                	mv	a0,s1
    80004422:	ffffe097          	auipc	ra,0xffffe
    80004426:	e6a080e7          	jalr	-406(ra) # 8000228c <wakeup>
  release(&lk->lk);
    8000442a:	854a                	mv	a0,s2
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	858080e7          	jalr	-1960(ra) # 80000c84 <release>
}
    80004434:	60e2                	ld	ra,24(sp)
    80004436:	6442                	ld	s0,16(sp)
    80004438:	64a2                	ld	s1,8(sp)
    8000443a:	6902                	ld	s2,0(sp)
    8000443c:	6105                	addi	sp,sp,32
    8000443e:	8082                	ret

0000000080004440 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004440:	7179                	addi	sp,sp,-48
    80004442:	f406                	sd	ra,40(sp)
    80004444:	f022                	sd	s0,32(sp)
    80004446:	ec26                	sd	s1,24(sp)
    80004448:	e84a                	sd	s2,16(sp)
    8000444a:	e44e                	sd	s3,8(sp)
    8000444c:	1800                	addi	s0,sp,48
    8000444e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004450:	00850913          	addi	s2,a0,8
    80004454:	854a                	mv	a0,s2
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	77a080e7          	jalr	1914(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000445e:	409c                	lw	a5,0(s1)
    80004460:	ef99                	bnez	a5,8000447e <holdingsleep+0x3e>
    80004462:	4481                	li	s1,0
  release(&lk->lk);
    80004464:	854a                	mv	a0,s2
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	81e080e7          	jalr	-2018(ra) # 80000c84 <release>
  return r;
}
    8000446e:	8526                	mv	a0,s1
    80004470:	70a2                	ld	ra,40(sp)
    80004472:	7402                	ld	s0,32(sp)
    80004474:	64e2                	ld	s1,24(sp)
    80004476:	6942                	ld	s2,16(sp)
    80004478:	69a2                	ld	s3,8(sp)
    8000447a:	6145                	addi	sp,sp,48
    8000447c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000447e:	0284a983          	lw	s3,40(s1)
    80004482:	ffffd097          	auipc	ra,0xffffd
    80004486:	58a080e7          	jalr	1418(ra) # 80001a0c <myproc>
    8000448a:	5904                	lw	s1,48(a0)
    8000448c:	413484b3          	sub	s1,s1,s3
    80004490:	0014b493          	seqz	s1,s1
    80004494:	bfc1                	j	80004464 <holdingsleep+0x24>

0000000080004496 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004496:	1141                	addi	sp,sp,-16
    80004498:	e406                	sd	ra,8(sp)
    8000449a:	e022                	sd	s0,0(sp)
    8000449c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000449e:	00004597          	auipc	a1,0x4
    800044a2:	28258593          	addi	a1,a1,642 # 80008720 <syscalls+0x258>
    800044a6:	0001d517          	auipc	a0,0x1d
    800044aa:	11250513          	addi	a0,a0,274 # 800215b8 <ftable>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	692080e7          	jalr	1682(ra) # 80000b40 <initlock>
}
    800044b6:	60a2                	ld	ra,8(sp)
    800044b8:	6402                	ld	s0,0(sp)
    800044ba:	0141                	addi	sp,sp,16
    800044bc:	8082                	ret

00000000800044be <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044be:	1101                	addi	sp,sp,-32
    800044c0:	ec06                	sd	ra,24(sp)
    800044c2:	e822                	sd	s0,16(sp)
    800044c4:	e426                	sd	s1,8(sp)
    800044c6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044c8:	0001d517          	auipc	a0,0x1d
    800044cc:	0f050513          	addi	a0,a0,240 # 800215b8 <ftable>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	700080e7          	jalr	1792(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044d8:	0001d497          	auipc	s1,0x1d
    800044dc:	0f848493          	addi	s1,s1,248 # 800215d0 <ftable+0x18>
    800044e0:	0001e717          	auipc	a4,0x1e
    800044e4:	09070713          	addi	a4,a4,144 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    800044e8:	40dc                	lw	a5,4(s1)
    800044ea:	cf99                	beqz	a5,80004508 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ec:	02848493          	addi	s1,s1,40
    800044f0:	fee49ce3          	bne	s1,a4,800044e8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044f4:	0001d517          	auipc	a0,0x1d
    800044f8:	0c450513          	addi	a0,a0,196 # 800215b8 <ftable>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	788080e7          	jalr	1928(ra) # 80000c84 <release>
  return 0;
    80004504:	4481                	li	s1,0
    80004506:	a819                	j	8000451c <filealloc+0x5e>
      f->ref = 1;
    80004508:	4785                	li	a5,1
    8000450a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000450c:	0001d517          	auipc	a0,0x1d
    80004510:	0ac50513          	addi	a0,a0,172 # 800215b8 <ftable>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	770080e7          	jalr	1904(ra) # 80000c84 <release>
}
    8000451c:	8526                	mv	a0,s1
    8000451e:	60e2                	ld	ra,24(sp)
    80004520:	6442                	ld	s0,16(sp)
    80004522:	64a2                	ld	s1,8(sp)
    80004524:	6105                	addi	sp,sp,32
    80004526:	8082                	ret

0000000080004528 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004528:	1101                	addi	sp,sp,-32
    8000452a:	ec06                	sd	ra,24(sp)
    8000452c:	e822                	sd	s0,16(sp)
    8000452e:	e426                	sd	s1,8(sp)
    80004530:	1000                	addi	s0,sp,32
    80004532:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004534:	0001d517          	auipc	a0,0x1d
    80004538:	08450513          	addi	a0,a0,132 # 800215b8 <ftable>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	694080e7          	jalr	1684(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004544:	40dc                	lw	a5,4(s1)
    80004546:	02f05263          	blez	a5,8000456a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000454a:	2785                	addiw	a5,a5,1
    8000454c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000454e:	0001d517          	auipc	a0,0x1d
    80004552:	06a50513          	addi	a0,a0,106 # 800215b8 <ftable>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	72e080e7          	jalr	1838(ra) # 80000c84 <release>
  return f;
}
    8000455e:	8526                	mv	a0,s1
    80004560:	60e2                	ld	ra,24(sp)
    80004562:	6442                	ld	s0,16(sp)
    80004564:	64a2                	ld	s1,8(sp)
    80004566:	6105                	addi	sp,sp,32
    80004568:	8082                	ret
    panic("filedup");
    8000456a:	00004517          	auipc	a0,0x4
    8000456e:	1be50513          	addi	a0,a0,446 # 80008728 <syscalls+0x260>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	fc8080e7          	jalr	-56(ra) # 8000053a <panic>

000000008000457a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000457a:	7139                	addi	sp,sp,-64
    8000457c:	fc06                	sd	ra,56(sp)
    8000457e:	f822                	sd	s0,48(sp)
    80004580:	f426                	sd	s1,40(sp)
    80004582:	f04a                	sd	s2,32(sp)
    80004584:	ec4e                	sd	s3,24(sp)
    80004586:	e852                	sd	s4,16(sp)
    80004588:	e456                	sd	s5,8(sp)
    8000458a:	0080                	addi	s0,sp,64
    8000458c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000458e:	0001d517          	auipc	a0,0x1d
    80004592:	02a50513          	addi	a0,a0,42 # 800215b8 <ftable>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	63a080e7          	jalr	1594(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    8000459e:	40dc                	lw	a5,4(s1)
    800045a0:	06f05163          	blez	a5,80004602 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045a4:	37fd                	addiw	a5,a5,-1
    800045a6:	0007871b          	sext.w	a4,a5
    800045aa:	c0dc                	sw	a5,4(s1)
    800045ac:	06e04363          	bgtz	a4,80004612 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045b0:	0004a903          	lw	s2,0(s1)
    800045b4:	0094ca83          	lbu	s5,9(s1)
    800045b8:	0104ba03          	ld	s4,16(s1)
    800045bc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045c0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045c4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045c8:	0001d517          	auipc	a0,0x1d
    800045cc:	ff050513          	addi	a0,a0,-16 # 800215b8 <ftable>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	6b4080e7          	jalr	1716(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    800045d8:	4785                	li	a5,1
    800045da:	04f90d63          	beq	s2,a5,80004634 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045de:	3979                	addiw	s2,s2,-2
    800045e0:	4785                	li	a5,1
    800045e2:	0527e063          	bltu	a5,s2,80004622 <fileclose+0xa8>
    begin_op();
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	acc080e7          	jalr	-1332(ra) # 800040b2 <begin_op>
    iput(ff.ip);
    800045ee:	854e                	mv	a0,s3
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	2a0080e7          	jalr	672(ra) # 80003890 <iput>
    end_op();
    800045f8:	00000097          	auipc	ra,0x0
    800045fc:	b38080e7          	jalr	-1224(ra) # 80004130 <end_op>
    80004600:	a00d                	j	80004622 <fileclose+0xa8>
    panic("fileclose");
    80004602:	00004517          	auipc	a0,0x4
    80004606:	12e50513          	addi	a0,a0,302 # 80008730 <syscalls+0x268>
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	f30080e7          	jalr	-208(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004612:	0001d517          	auipc	a0,0x1d
    80004616:	fa650513          	addi	a0,a0,-90 # 800215b8 <ftable>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	66a080e7          	jalr	1642(ra) # 80000c84 <release>
  }
}
    80004622:	70e2                	ld	ra,56(sp)
    80004624:	7442                	ld	s0,48(sp)
    80004626:	74a2                	ld	s1,40(sp)
    80004628:	7902                	ld	s2,32(sp)
    8000462a:	69e2                	ld	s3,24(sp)
    8000462c:	6a42                	ld	s4,16(sp)
    8000462e:	6aa2                	ld	s5,8(sp)
    80004630:	6121                	addi	sp,sp,64
    80004632:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004634:	85d6                	mv	a1,s5
    80004636:	8552                	mv	a0,s4
    80004638:	00000097          	auipc	ra,0x0
    8000463c:	34c080e7          	jalr	844(ra) # 80004984 <pipeclose>
    80004640:	b7cd                	j	80004622 <fileclose+0xa8>

0000000080004642 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004642:	715d                	addi	sp,sp,-80
    80004644:	e486                	sd	ra,72(sp)
    80004646:	e0a2                	sd	s0,64(sp)
    80004648:	fc26                	sd	s1,56(sp)
    8000464a:	f84a                	sd	s2,48(sp)
    8000464c:	f44e                	sd	s3,40(sp)
    8000464e:	0880                	addi	s0,sp,80
    80004650:	84aa                	mv	s1,a0
    80004652:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004654:	ffffd097          	auipc	ra,0xffffd
    80004658:	3b8080e7          	jalr	952(ra) # 80001a0c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000465c:	409c                	lw	a5,0(s1)
    8000465e:	37f9                	addiw	a5,a5,-2
    80004660:	4705                	li	a4,1
    80004662:	04f76763          	bltu	a4,a5,800046b0 <filestat+0x6e>
    80004666:	892a                	mv	s2,a0
    ilock(f->ip);
    80004668:	6c88                	ld	a0,24(s1)
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	06c080e7          	jalr	108(ra) # 800036d6 <ilock>
    stati(f->ip, &st);
    80004672:	fb840593          	addi	a1,s0,-72
    80004676:	6c88                	ld	a0,24(s1)
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	2e8080e7          	jalr	744(ra) # 80003960 <stati>
    iunlock(f->ip);
    80004680:	6c88                	ld	a0,24(s1)
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	116080e7          	jalr	278(ra) # 80003798 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000468a:	46e1                	li	a3,24
    8000468c:	fb840613          	addi	a2,s0,-72
    80004690:	85ce                	mv	a1,s3
    80004692:	05093503          	ld	a0,80(s2)
    80004696:	ffffd097          	auipc	ra,0xffffd
    8000469a:	fc4080e7          	jalr	-60(ra) # 8000165a <copyout>
    8000469e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046a2:	60a6                	ld	ra,72(sp)
    800046a4:	6406                	ld	s0,64(sp)
    800046a6:	74e2                	ld	s1,56(sp)
    800046a8:	7942                	ld	s2,48(sp)
    800046aa:	79a2                	ld	s3,40(sp)
    800046ac:	6161                	addi	sp,sp,80
    800046ae:	8082                	ret
  return -1;
    800046b0:	557d                	li	a0,-1
    800046b2:	bfc5                	j	800046a2 <filestat+0x60>

00000000800046b4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046b4:	7179                	addi	sp,sp,-48
    800046b6:	f406                	sd	ra,40(sp)
    800046b8:	f022                	sd	s0,32(sp)
    800046ba:	ec26                	sd	s1,24(sp)
    800046bc:	e84a                	sd	s2,16(sp)
    800046be:	e44e                	sd	s3,8(sp)
    800046c0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046c2:	00854783          	lbu	a5,8(a0)
    800046c6:	c3d5                	beqz	a5,8000476a <fileread+0xb6>
    800046c8:	84aa                	mv	s1,a0
    800046ca:	89ae                	mv	s3,a1
    800046cc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ce:	411c                	lw	a5,0(a0)
    800046d0:	4705                	li	a4,1
    800046d2:	04e78963          	beq	a5,a4,80004724 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046d6:	470d                	li	a4,3
    800046d8:	04e78d63          	beq	a5,a4,80004732 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046dc:	4709                	li	a4,2
    800046de:	06e79e63          	bne	a5,a4,8000475a <fileread+0xa6>
    ilock(f->ip);
    800046e2:	6d08                	ld	a0,24(a0)
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	ff2080e7          	jalr	-14(ra) # 800036d6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046ec:	874a                	mv	a4,s2
    800046ee:	5094                	lw	a3,32(s1)
    800046f0:	864e                	mv	a2,s3
    800046f2:	4585                	li	a1,1
    800046f4:	6c88                	ld	a0,24(s1)
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	294080e7          	jalr	660(ra) # 8000398a <readi>
    800046fe:	892a                	mv	s2,a0
    80004700:	00a05563          	blez	a0,8000470a <fileread+0x56>
      f->off += r;
    80004704:	509c                	lw	a5,32(s1)
    80004706:	9fa9                	addw	a5,a5,a0
    80004708:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000470a:	6c88                	ld	a0,24(s1)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	08c080e7          	jalr	140(ra) # 80003798 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004714:	854a                	mv	a0,s2
    80004716:	70a2                	ld	ra,40(sp)
    80004718:	7402                	ld	s0,32(sp)
    8000471a:	64e2                	ld	s1,24(sp)
    8000471c:	6942                	ld	s2,16(sp)
    8000471e:	69a2                	ld	s3,8(sp)
    80004720:	6145                	addi	sp,sp,48
    80004722:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004724:	6908                	ld	a0,16(a0)
    80004726:	00000097          	auipc	ra,0x0
    8000472a:	3c0080e7          	jalr	960(ra) # 80004ae6 <piperead>
    8000472e:	892a                	mv	s2,a0
    80004730:	b7d5                	j	80004714 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004732:	02451783          	lh	a5,36(a0)
    80004736:	03079693          	slli	a3,a5,0x30
    8000473a:	92c1                	srli	a3,a3,0x30
    8000473c:	4725                	li	a4,9
    8000473e:	02d76863          	bltu	a4,a3,8000476e <fileread+0xba>
    80004742:	0792                	slli	a5,a5,0x4
    80004744:	0001d717          	auipc	a4,0x1d
    80004748:	dd470713          	addi	a4,a4,-556 # 80021518 <devsw>
    8000474c:	97ba                	add	a5,a5,a4
    8000474e:	639c                	ld	a5,0(a5)
    80004750:	c38d                	beqz	a5,80004772 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004752:	4505                	li	a0,1
    80004754:	9782                	jalr	a5
    80004756:	892a                	mv	s2,a0
    80004758:	bf75                	j	80004714 <fileread+0x60>
    panic("fileread");
    8000475a:	00004517          	auipc	a0,0x4
    8000475e:	fe650513          	addi	a0,a0,-26 # 80008740 <syscalls+0x278>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	dd8080e7          	jalr	-552(ra) # 8000053a <panic>
    return -1;
    8000476a:	597d                	li	s2,-1
    8000476c:	b765                	j	80004714 <fileread+0x60>
      return -1;
    8000476e:	597d                	li	s2,-1
    80004770:	b755                	j	80004714 <fileread+0x60>
    80004772:	597d                	li	s2,-1
    80004774:	b745                	j	80004714 <fileread+0x60>

0000000080004776 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004776:	715d                	addi	sp,sp,-80
    80004778:	e486                	sd	ra,72(sp)
    8000477a:	e0a2                	sd	s0,64(sp)
    8000477c:	fc26                	sd	s1,56(sp)
    8000477e:	f84a                	sd	s2,48(sp)
    80004780:	f44e                	sd	s3,40(sp)
    80004782:	f052                	sd	s4,32(sp)
    80004784:	ec56                	sd	s5,24(sp)
    80004786:	e85a                	sd	s6,16(sp)
    80004788:	e45e                	sd	s7,8(sp)
    8000478a:	e062                	sd	s8,0(sp)
    8000478c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000478e:	00954783          	lbu	a5,9(a0)
    80004792:	10078663          	beqz	a5,8000489e <filewrite+0x128>
    80004796:	892a                	mv	s2,a0
    80004798:	8b2e                	mv	s6,a1
    8000479a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000479c:	411c                	lw	a5,0(a0)
    8000479e:	4705                	li	a4,1
    800047a0:	02e78263          	beq	a5,a4,800047c4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a4:	470d                	li	a4,3
    800047a6:	02e78663          	beq	a5,a4,800047d2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047aa:	4709                	li	a4,2
    800047ac:	0ee79163          	bne	a5,a4,8000488e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047b0:	0ac05d63          	blez	a2,8000486a <filewrite+0xf4>
    int i = 0;
    800047b4:	4981                	li	s3,0
    800047b6:	6b85                	lui	s7,0x1
    800047b8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047bc:	6c05                	lui	s8,0x1
    800047be:	c00c0c1b          	addiw	s8,s8,-1024
    800047c2:	a861                	j	8000485a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047c4:	6908                	ld	a0,16(a0)
    800047c6:	00000097          	auipc	ra,0x0
    800047ca:	22e080e7          	jalr	558(ra) # 800049f4 <pipewrite>
    800047ce:	8a2a                	mv	s4,a0
    800047d0:	a045                	j	80004870 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047d2:	02451783          	lh	a5,36(a0)
    800047d6:	03079693          	slli	a3,a5,0x30
    800047da:	92c1                	srli	a3,a3,0x30
    800047dc:	4725                	li	a4,9
    800047de:	0cd76263          	bltu	a4,a3,800048a2 <filewrite+0x12c>
    800047e2:	0792                	slli	a5,a5,0x4
    800047e4:	0001d717          	auipc	a4,0x1d
    800047e8:	d3470713          	addi	a4,a4,-716 # 80021518 <devsw>
    800047ec:	97ba                	add	a5,a5,a4
    800047ee:	679c                	ld	a5,8(a5)
    800047f0:	cbdd                	beqz	a5,800048a6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047f2:	4505                	li	a0,1
    800047f4:	9782                	jalr	a5
    800047f6:	8a2a                	mv	s4,a0
    800047f8:	a8a5                	j	80004870 <filewrite+0xfa>
    800047fa:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	8b4080e7          	jalr	-1868(ra) # 800040b2 <begin_op>
      ilock(f->ip);
    80004806:	01893503          	ld	a0,24(s2)
    8000480a:	fffff097          	auipc	ra,0xfffff
    8000480e:	ecc080e7          	jalr	-308(ra) # 800036d6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004812:	8756                	mv	a4,s5
    80004814:	02092683          	lw	a3,32(s2)
    80004818:	01698633          	add	a2,s3,s6
    8000481c:	4585                	li	a1,1
    8000481e:	01893503          	ld	a0,24(s2)
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	260080e7          	jalr	608(ra) # 80003a82 <writei>
    8000482a:	84aa                	mv	s1,a0
    8000482c:	00a05763          	blez	a0,8000483a <filewrite+0xc4>
        f->off += r;
    80004830:	02092783          	lw	a5,32(s2)
    80004834:	9fa9                	addw	a5,a5,a0
    80004836:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000483a:	01893503          	ld	a0,24(s2)
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	f5a080e7          	jalr	-166(ra) # 80003798 <iunlock>
      end_op();
    80004846:	00000097          	auipc	ra,0x0
    8000484a:	8ea080e7          	jalr	-1814(ra) # 80004130 <end_op>

      if(r != n1){
    8000484e:	009a9f63          	bne	s5,s1,8000486c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004852:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004856:	0149db63          	bge	s3,s4,8000486c <filewrite+0xf6>
      int n1 = n - i;
    8000485a:	413a04bb          	subw	s1,s4,s3
    8000485e:	0004879b          	sext.w	a5,s1
    80004862:	f8fbdce3          	bge	s7,a5,800047fa <filewrite+0x84>
    80004866:	84e2                	mv	s1,s8
    80004868:	bf49                	j	800047fa <filewrite+0x84>
    int i = 0;
    8000486a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000486c:	013a1f63          	bne	s4,s3,8000488a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004870:	8552                	mv	a0,s4
    80004872:	60a6                	ld	ra,72(sp)
    80004874:	6406                	ld	s0,64(sp)
    80004876:	74e2                	ld	s1,56(sp)
    80004878:	7942                	ld	s2,48(sp)
    8000487a:	79a2                	ld	s3,40(sp)
    8000487c:	7a02                	ld	s4,32(sp)
    8000487e:	6ae2                	ld	s5,24(sp)
    80004880:	6b42                	ld	s6,16(sp)
    80004882:	6ba2                	ld	s7,8(sp)
    80004884:	6c02                	ld	s8,0(sp)
    80004886:	6161                	addi	sp,sp,80
    80004888:	8082                	ret
    ret = (i == n ? n : -1);
    8000488a:	5a7d                	li	s4,-1
    8000488c:	b7d5                	j	80004870 <filewrite+0xfa>
    panic("filewrite");
    8000488e:	00004517          	auipc	a0,0x4
    80004892:	ec250513          	addi	a0,a0,-318 # 80008750 <syscalls+0x288>
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	ca4080e7          	jalr	-860(ra) # 8000053a <panic>
    return -1;
    8000489e:	5a7d                	li	s4,-1
    800048a0:	bfc1                	j	80004870 <filewrite+0xfa>
      return -1;
    800048a2:	5a7d                	li	s4,-1
    800048a4:	b7f1                	j	80004870 <filewrite+0xfa>
    800048a6:	5a7d                	li	s4,-1
    800048a8:	b7e1                	j	80004870 <filewrite+0xfa>

00000000800048aa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048aa:	7179                	addi	sp,sp,-48
    800048ac:	f406                	sd	ra,40(sp)
    800048ae:	f022                	sd	s0,32(sp)
    800048b0:	ec26                	sd	s1,24(sp)
    800048b2:	e84a                	sd	s2,16(sp)
    800048b4:	e44e                	sd	s3,8(sp)
    800048b6:	e052                	sd	s4,0(sp)
    800048b8:	1800                	addi	s0,sp,48
    800048ba:	84aa                	mv	s1,a0
    800048bc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048be:	0005b023          	sd	zero,0(a1)
    800048c2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	bf8080e7          	jalr	-1032(ra) # 800044be <filealloc>
    800048ce:	e088                	sd	a0,0(s1)
    800048d0:	c551                	beqz	a0,8000495c <pipealloc+0xb2>
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	bec080e7          	jalr	-1044(ra) # 800044be <filealloc>
    800048da:	00aa3023          	sd	a0,0(s4)
    800048de:	c92d                	beqz	a0,80004950 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	200080e7          	jalr	512(ra) # 80000ae0 <kalloc>
    800048e8:	892a                	mv	s2,a0
    800048ea:	c125                	beqz	a0,8000494a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048ec:	4985                	li	s3,1
    800048ee:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048f2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048f6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048fa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048fe:	00004597          	auipc	a1,0x4
    80004902:	e6258593          	addi	a1,a1,-414 # 80008760 <syscalls+0x298>
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	23a080e7          	jalr	570(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    8000490e:	609c                	ld	a5,0(s1)
    80004910:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004914:	609c                	ld	a5,0(s1)
    80004916:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000491a:	609c                	ld	a5,0(s1)
    8000491c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004920:	609c                	ld	a5,0(s1)
    80004922:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004926:	000a3783          	ld	a5,0(s4)
    8000492a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000492e:	000a3783          	ld	a5,0(s4)
    80004932:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004936:	000a3783          	ld	a5,0(s4)
    8000493a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000493e:	000a3783          	ld	a5,0(s4)
    80004942:	0127b823          	sd	s2,16(a5)
  return 0;
    80004946:	4501                	li	a0,0
    80004948:	a025                	j	80004970 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000494a:	6088                	ld	a0,0(s1)
    8000494c:	e501                	bnez	a0,80004954 <pipealloc+0xaa>
    8000494e:	a039                	j	8000495c <pipealloc+0xb2>
    80004950:	6088                	ld	a0,0(s1)
    80004952:	c51d                	beqz	a0,80004980 <pipealloc+0xd6>
    fileclose(*f0);
    80004954:	00000097          	auipc	ra,0x0
    80004958:	c26080e7          	jalr	-986(ra) # 8000457a <fileclose>
  if(*f1)
    8000495c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004960:	557d                	li	a0,-1
  if(*f1)
    80004962:	c799                	beqz	a5,80004970 <pipealloc+0xc6>
    fileclose(*f1);
    80004964:	853e                	mv	a0,a5
    80004966:	00000097          	auipc	ra,0x0
    8000496a:	c14080e7          	jalr	-1004(ra) # 8000457a <fileclose>
  return -1;
    8000496e:	557d                	li	a0,-1
}
    80004970:	70a2                	ld	ra,40(sp)
    80004972:	7402                	ld	s0,32(sp)
    80004974:	64e2                	ld	s1,24(sp)
    80004976:	6942                	ld	s2,16(sp)
    80004978:	69a2                	ld	s3,8(sp)
    8000497a:	6a02                	ld	s4,0(sp)
    8000497c:	6145                	addi	sp,sp,48
    8000497e:	8082                	ret
  return -1;
    80004980:	557d                	li	a0,-1
    80004982:	b7fd                	j	80004970 <pipealloc+0xc6>

0000000080004984 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004984:	1101                	addi	sp,sp,-32
    80004986:	ec06                	sd	ra,24(sp)
    80004988:	e822                	sd	s0,16(sp)
    8000498a:	e426                	sd	s1,8(sp)
    8000498c:	e04a                	sd	s2,0(sp)
    8000498e:	1000                	addi	s0,sp,32
    80004990:	84aa                	mv	s1,a0
    80004992:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	23c080e7          	jalr	572(ra) # 80000bd0 <acquire>
  if(writable){
    8000499c:	02090d63          	beqz	s2,800049d6 <pipeclose+0x52>
    pi->writeopen = 0;
    800049a0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049a4:	21848513          	addi	a0,s1,536
    800049a8:	ffffe097          	auipc	ra,0xffffe
    800049ac:	8e4080e7          	jalr	-1820(ra) # 8000228c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049b0:	2204b783          	ld	a5,544(s1)
    800049b4:	eb95                	bnez	a5,800049e8 <pipeclose+0x64>
    release(&pi->lock);
    800049b6:	8526                	mv	a0,s1
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	2cc080e7          	jalr	716(ra) # 80000c84 <release>
    kfree((char*)pi);
    800049c0:	8526                	mv	a0,s1
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	020080e7          	jalr	32(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    800049ca:	60e2                	ld	ra,24(sp)
    800049cc:	6442                	ld	s0,16(sp)
    800049ce:	64a2                	ld	s1,8(sp)
    800049d0:	6902                	ld	s2,0(sp)
    800049d2:	6105                	addi	sp,sp,32
    800049d4:	8082                	ret
    pi->readopen = 0;
    800049d6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049da:	21c48513          	addi	a0,s1,540
    800049de:	ffffe097          	auipc	ra,0xffffe
    800049e2:	8ae080e7          	jalr	-1874(ra) # 8000228c <wakeup>
    800049e6:	b7e9                	j	800049b0 <pipeclose+0x2c>
    release(&pi->lock);
    800049e8:	8526                	mv	a0,s1
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	29a080e7          	jalr	666(ra) # 80000c84 <release>
}
    800049f2:	bfe1                	j	800049ca <pipeclose+0x46>

00000000800049f4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049f4:	711d                	addi	sp,sp,-96
    800049f6:	ec86                	sd	ra,88(sp)
    800049f8:	e8a2                	sd	s0,80(sp)
    800049fa:	e4a6                	sd	s1,72(sp)
    800049fc:	e0ca                	sd	s2,64(sp)
    800049fe:	fc4e                	sd	s3,56(sp)
    80004a00:	f852                	sd	s4,48(sp)
    80004a02:	f456                	sd	s5,40(sp)
    80004a04:	f05a                	sd	s6,32(sp)
    80004a06:	ec5e                	sd	s7,24(sp)
    80004a08:	e862                	sd	s8,16(sp)
    80004a0a:	1080                	addi	s0,sp,96
    80004a0c:	84aa                	mv	s1,a0
    80004a0e:	8aae                	mv	s5,a1
    80004a10:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a12:	ffffd097          	auipc	ra,0xffffd
    80004a16:	ffa080e7          	jalr	-6(ra) # 80001a0c <myproc>
    80004a1a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a1c:	8526                	mv	a0,s1
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	1b2080e7          	jalr	434(ra) # 80000bd0 <acquire>
  while(i < n){
    80004a26:	0b405363          	blez	s4,80004acc <pipewrite+0xd8>
  int i = 0;
    80004a2a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a2c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a2e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a32:	21c48b93          	addi	s7,s1,540
    80004a36:	a089                	j	80004a78 <pipewrite+0x84>
      release(&pi->lock);
    80004a38:	8526                	mv	a0,s1
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	24a080e7          	jalr	586(ra) # 80000c84 <release>
      return -1;
    80004a42:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a44:	854a                	mv	a0,s2
    80004a46:	60e6                	ld	ra,88(sp)
    80004a48:	6446                	ld	s0,80(sp)
    80004a4a:	64a6                	ld	s1,72(sp)
    80004a4c:	6906                	ld	s2,64(sp)
    80004a4e:	79e2                	ld	s3,56(sp)
    80004a50:	7a42                	ld	s4,48(sp)
    80004a52:	7aa2                	ld	s5,40(sp)
    80004a54:	7b02                	ld	s6,32(sp)
    80004a56:	6be2                	ld	s7,24(sp)
    80004a58:	6c42                	ld	s8,16(sp)
    80004a5a:	6125                	addi	sp,sp,96
    80004a5c:	8082                	ret
      wakeup(&pi->nread);
    80004a5e:	8562                	mv	a0,s8
    80004a60:	ffffe097          	auipc	ra,0xffffe
    80004a64:	82c080e7          	jalr	-2004(ra) # 8000228c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a68:	85a6                	mv	a1,s1
    80004a6a:	855e                	mv	a0,s7
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	694080e7          	jalr	1684(ra) # 80002100 <sleep>
  while(i < n){
    80004a74:	05495d63          	bge	s2,s4,80004ace <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004a78:	2204a783          	lw	a5,544(s1)
    80004a7c:	dfd5                	beqz	a5,80004a38 <pipewrite+0x44>
    80004a7e:	0289a783          	lw	a5,40(s3)
    80004a82:	fbdd                	bnez	a5,80004a38 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a84:	2184a783          	lw	a5,536(s1)
    80004a88:	21c4a703          	lw	a4,540(s1)
    80004a8c:	2007879b          	addiw	a5,a5,512
    80004a90:	fcf707e3          	beq	a4,a5,80004a5e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a94:	4685                	li	a3,1
    80004a96:	01590633          	add	a2,s2,s5
    80004a9a:	faf40593          	addi	a1,s0,-81
    80004a9e:	0509b503          	ld	a0,80(s3)
    80004aa2:	ffffd097          	auipc	ra,0xffffd
    80004aa6:	c44080e7          	jalr	-956(ra) # 800016e6 <copyin>
    80004aaa:	03650263          	beq	a0,s6,80004ace <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004aae:	21c4a783          	lw	a5,540(s1)
    80004ab2:	0017871b          	addiw	a4,a5,1
    80004ab6:	20e4ae23          	sw	a4,540(s1)
    80004aba:	1ff7f793          	andi	a5,a5,511
    80004abe:	97a6                	add	a5,a5,s1
    80004ac0:	faf44703          	lbu	a4,-81(s0)
    80004ac4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ac8:	2905                	addiw	s2,s2,1
    80004aca:	b76d                	j	80004a74 <pipewrite+0x80>
  int i = 0;
    80004acc:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ace:	21848513          	addi	a0,s1,536
    80004ad2:	ffffd097          	auipc	ra,0xffffd
    80004ad6:	7ba080e7          	jalr	1978(ra) # 8000228c <wakeup>
  release(&pi->lock);
    80004ada:	8526                	mv	a0,s1
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	1a8080e7          	jalr	424(ra) # 80000c84 <release>
  return i;
    80004ae4:	b785                	j	80004a44 <pipewrite+0x50>

0000000080004ae6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ae6:	715d                	addi	sp,sp,-80
    80004ae8:	e486                	sd	ra,72(sp)
    80004aea:	e0a2                	sd	s0,64(sp)
    80004aec:	fc26                	sd	s1,56(sp)
    80004aee:	f84a                	sd	s2,48(sp)
    80004af0:	f44e                	sd	s3,40(sp)
    80004af2:	f052                	sd	s4,32(sp)
    80004af4:	ec56                	sd	s5,24(sp)
    80004af6:	e85a                	sd	s6,16(sp)
    80004af8:	0880                	addi	s0,sp,80
    80004afa:	84aa                	mv	s1,a0
    80004afc:	892e                	mv	s2,a1
    80004afe:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b00:	ffffd097          	auipc	ra,0xffffd
    80004b04:	f0c080e7          	jalr	-244(ra) # 80001a0c <myproc>
    80004b08:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	0c4080e7          	jalr	196(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b14:	2184a703          	lw	a4,536(s1)
    80004b18:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b1c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b20:	02f71463          	bne	a4,a5,80004b48 <piperead+0x62>
    80004b24:	2244a783          	lw	a5,548(s1)
    80004b28:	c385                	beqz	a5,80004b48 <piperead+0x62>
    if(pr->killed){
    80004b2a:	028a2783          	lw	a5,40(s4)
    80004b2e:	ebc9                	bnez	a5,80004bc0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b30:	85a6                	mv	a1,s1
    80004b32:	854e                	mv	a0,s3
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	5cc080e7          	jalr	1484(ra) # 80002100 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b3c:	2184a703          	lw	a4,536(s1)
    80004b40:	21c4a783          	lw	a5,540(s1)
    80004b44:	fef700e3          	beq	a4,a5,80004b24 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b48:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b4a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b4c:	05505463          	blez	s5,80004b94 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004b50:	2184a783          	lw	a5,536(s1)
    80004b54:	21c4a703          	lw	a4,540(s1)
    80004b58:	02f70e63          	beq	a4,a5,80004b94 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b5c:	0017871b          	addiw	a4,a5,1
    80004b60:	20e4ac23          	sw	a4,536(s1)
    80004b64:	1ff7f793          	andi	a5,a5,511
    80004b68:	97a6                	add	a5,a5,s1
    80004b6a:	0187c783          	lbu	a5,24(a5)
    80004b6e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b72:	4685                	li	a3,1
    80004b74:	fbf40613          	addi	a2,s0,-65
    80004b78:	85ca                	mv	a1,s2
    80004b7a:	050a3503          	ld	a0,80(s4)
    80004b7e:	ffffd097          	auipc	ra,0xffffd
    80004b82:	adc080e7          	jalr	-1316(ra) # 8000165a <copyout>
    80004b86:	01650763          	beq	a0,s6,80004b94 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b8a:	2985                	addiw	s3,s3,1
    80004b8c:	0905                	addi	s2,s2,1
    80004b8e:	fd3a91e3          	bne	s5,s3,80004b50 <piperead+0x6a>
    80004b92:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b94:	21c48513          	addi	a0,s1,540
    80004b98:	ffffd097          	auipc	ra,0xffffd
    80004b9c:	6f4080e7          	jalr	1780(ra) # 8000228c <wakeup>
  release(&pi->lock);
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	0e2080e7          	jalr	226(ra) # 80000c84 <release>
  return i;
}
    80004baa:	854e                	mv	a0,s3
    80004bac:	60a6                	ld	ra,72(sp)
    80004bae:	6406                	ld	s0,64(sp)
    80004bb0:	74e2                	ld	s1,56(sp)
    80004bb2:	7942                	ld	s2,48(sp)
    80004bb4:	79a2                	ld	s3,40(sp)
    80004bb6:	7a02                	ld	s4,32(sp)
    80004bb8:	6ae2                	ld	s5,24(sp)
    80004bba:	6b42                	ld	s6,16(sp)
    80004bbc:	6161                	addi	sp,sp,80
    80004bbe:	8082                	ret
      release(&pi->lock);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	0c2080e7          	jalr	194(ra) # 80000c84 <release>
      return -1;
    80004bca:	59fd                	li	s3,-1
    80004bcc:	bff9                	j	80004baa <piperead+0xc4>

0000000080004bce <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bce:	de010113          	addi	sp,sp,-544
    80004bd2:	20113c23          	sd	ra,536(sp)
    80004bd6:	20813823          	sd	s0,528(sp)
    80004bda:	20913423          	sd	s1,520(sp)
    80004bde:	21213023          	sd	s2,512(sp)
    80004be2:	ffce                	sd	s3,504(sp)
    80004be4:	fbd2                	sd	s4,496(sp)
    80004be6:	f7d6                	sd	s5,488(sp)
    80004be8:	f3da                	sd	s6,480(sp)
    80004bea:	efde                	sd	s7,472(sp)
    80004bec:	ebe2                	sd	s8,464(sp)
    80004bee:	e7e6                	sd	s9,456(sp)
    80004bf0:	e3ea                	sd	s10,448(sp)
    80004bf2:	ff6e                	sd	s11,440(sp)
    80004bf4:	1400                	addi	s0,sp,544
    80004bf6:	892a                	mv	s2,a0
    80004bf8:	dea43423          	sd	a0,-536(s0)
    80004bfc:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c00:	ffffd097          	auipc	ra,0xffffd
    80004c04:	e0c080e7          	jalr	-500(ra) # 80001a0c <myproc>
    80004c08:	84aa                	mv	s1,a0

  begin_op();
    80004c0a:	fffff097          	auipc	ra,0xfffff
    80004c0e:	4a8080e7          	jalr	1192(ra) # 800040b2 <begin_op>

  if((ip = namei(path)) == 0){
    80004c12:	854a                	mv	a0,s2
    80004c14:	fffff097          	auipc	ra,0xfffff
    80004c18:	27e080e7          	jalr	638(ra) # 80003e92 <namei>
    80004c1c:	c93d                	beqz	a0,80004c92 <exec+0xc4>
    80004c1e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c20:	fffff097          	auipc	ra,0xfffff
    80004c24:	ab6080e7          	jalr	-1354(ra) # 800036d6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c28:	04000713          	li	a4,64
    80004c2c:	4681                	li	a3,0
    80004c2e:	e5040613          	addi	a2,s0,-432
    80004c32:	4581                	li	a1,0
    80004c34:	8556                	mv	a0,s5
    80004c36:	fffff097          	auipc	ra,0xfffff
    80004c3a:	d54080e7          	jalr	-684(ra) # 8000398a <readi>
    80004c3e:	04000793          	li	a5,64
    80004c42:	00f51a63          	bne	a0,a5,80004c56 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c46:	e5042703          	lw	a4,-432(s0)
    80004c4a:	464c47b7          	lui	a5,0x464c4
    80004c4e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c52:	04f70663          	beq	a4,a5,80004c9e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c56:	8556                	mv	a0,s5
    80004c58:	fffff097          	auipc	ra,0xfffff
    80004c5c:	ce0080e7          	jalr	-800(ra) # 80003938 <iunlockput>
    end_op();
    80004c60:	fffff097          	auipc	ra,0xfffff
    80004c64:	4d0080e7          	jalr	1232(ra) # 80004130 <end_op>
  }
  return -1;
    80004c68:	557d                	li	a0,-1
}
    80004c6a:	21813083          	ld	ra,536(sp)
    80004c6e:	21013403          	ld	s0,528(sp)
    80004c72:	20813483          	ld	s1,520(sp)
    80004c76:	20013903          	ld	s2,512(sp)
    80004c7a:	79fe                	ld	s3,504(sp)
    80004c7c:	7a5e                	ld	s4,496(sp)
    80004c7e:	7abe                	ld	s5,488(sp)
    80004c80:	7b1e                	ld	s6,480(sp)
    80004c82:	6bfe                	ld	s7,472(sp)
    80004c84:	6c5e                	ld	s8,464(sp)
    80004c86:	6cbe                	ld	s9,456(sp)
    80004c88:	6d1e                	ld	s10,448(sp)
    80004c8a:	7dfa                	ld	s11,440(sp)
    80004c8c:	22010113          	addi	sp,sp,544
    80004c90:	8082                	ret
    end_op();
    80004c92:	fffff097          	auipc	ra,0xfffff
    80004c96:	49e080e7          	jalr	1182(ra) # 80004130 <end_op>
    return -1;
    80004c9a:	557d                	li	a0,-1
    80004c9c:	b7f9                	j	80004c6a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffd097          	auipc	ra,0xffffd
    80004ca4:	e5c080e7          	jalr	-420(ra) # 80001afc <proc_pagetable>
    80004ca8:	8b2a                	mv	s6,a0
    80004caa:	d555                	beqz	a0,80004c56 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cac:	e7042783          	lw	a5,-400(s0)
    80004cb0:	e8845703          	lhu	a4,-376(s0)
    80004cb4:	c735                	beqz	a4,80004d20 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cb6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cb8:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004cbc:	6a05                	lui	s4,0x1
    80004cbe:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004cc2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004cc6:	6d85                	lui	s11,0x1
    80004cc8:	7d7d                	lui	s10,0xfffff
    80004cca:	ac1d                	j	80004f00 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ccc:	00004517          	auipc	a0,0x4
    80004cd0:	a9c50513          	addi	a0,a0,-1380 # 80008768 <syscalls+0x2a0>
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	866080e7          	jalr	-1946(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cdc:	874a                	mv	a4,s2
    80004cde:	009c86bb          	addw	a3,s9,s1
    80004ce2:	4581                	li	a1,0
    80004ce4:	8556                	mv	a0,s5
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	ca4080e7          	jalr	-860(ra) # 8000398a <readi>
    80004cee:	2501                	sext.w	a0,a0
    80004cf0:	1aa91863          	bne	s2,a0,80004ea0 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004cf4:	009d84bb          	addw	s1,s11,s1
    80004cf8:	013d09bb          	addw	s3,s10,s3
    80004cfc:	1f74f263          	bgeu	s1,s7,80004ee0 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d00:	02049593          	slli	a1,s1,0x20
    80004d04:	9181                	srli	a1,a1,0x20
    80004d06:	95e2                	add	a1,a1,s8
    80004d08:	855a                	mv	a0,s6
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	348080e7          	jalr	840(ra) # 80001052 <walkaddr>
    80004d12:	862a                	mv	a2,a0
    if(pa == 0)
    80004d14:	dd45                	beqz	a0,80004ccc <exec+0xfe>
      n = PGSIZE;
    80004d16:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d18:	fd49f2e3          	bgeu	s3,s4,80004cdc <exec+0x10e>
      n = sz - i;
    80004d1c:	894e                	mv	s2,s3
    80004d1e:	bf7d                	j	80004cdc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d20:	4481                	li	s1,0
  iunlockput(ip);
    80004d22:	8556                	mv	a0,s5
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	c14080e7          	jalr	-1004(ra) # 80003938 <iunlockput>
  end_op();
    80004d2c:	fffff097          	auipc	ra,0xfffff
    80004d30:	404080e7          	jalr	1028(ra) # 80004130 <end_op>
  p = myproc();
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	cd8080e7          	jalr	-808(ra) # 80001a0c <myproc>
    80004d3c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d3e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d42:	6785                	lui	a5,0x1
    80004d44:	17fd                	addi	a5,a5,-1
    80004d46:	97a6                	add	a5,a5,s1
    80004d48:	777d                	lui	a4,0xfffff
    80004d4a:	8ff9                	and	a5,a5,a4
    80004d4c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d50:	6609                	lui	a2,0x2
    80004d52:	963e                	add	a2,a2,a5
    80004d54:	85be                	mv	a1,a5
    80004d56:	855a                	mv	a0,s6
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	6ae080e7          	jalr	1710(ra) # 80001406 <uvmalloc>
    80004d60:	8c2a                	mv	s8,a0
  ip = 0;
    80004d62:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d64:	12050e63          	beqz	a0,80004ea0 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d68:	75f9                	lui	a1,0xffffe
    80004d6a:	95aa                	add	a1,a1,a0
    80004d6c:	855a                	mv	a0,s6
    80004d6e:	ffffd097          	auipc	ra,0xffffd
    80004d72:	8ba080e7          	jalr	-1862(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d76:	7afd                	lui	s5,0xfffff
    80004d78:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d7a:	df043783          	ld	a5,-528(s0)
    80004d7e:	6388                	ld	a0,0(a5)
    80004d80:	c925                	beqz	a0,80004df0 <exec+0x222>
    80004d82:	e9040993          	addi	s3,s0,-368
    80004d86:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d8a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d8c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	0ba080e7          	jalr	186(ra) # 80000e48 <strlen>
    80004d96:	0015079b          	addiw	a5,a0,1
    80004d9a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d9e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004da2:	13596363          	bltu	s2,s5,80004ec8 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004da6:	df043d83          	ld	s11,-528(s0)
    80004daa:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004dae:	8552                	mv	a0,s4
    80004db0:	ffffc097          	auipc	ra,0xffffc
    80004db4:	098080e7          	jalr	152(ra) # 80000e48 <strlen>
    80004db8:	0015069b          	addiw	a3,a0,1
    80004dbc:	8652                	mv	a2,s4
    80004dbe:	85ca                	mv	a1,s2
    80004dc0:	855a                	mv	a0,s6
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	898080e7          	jalr	-1896(ra) # 8000165a <copyout>
    80004dca:	10054363          	bltz	a0,80004ed0 <exec+0x302>
    ustack[argc] = sp;
    80004dce:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dd2:	0485                	addi	s1,s1,1
    80004dd4:	008d8793          	addi	a5,s11,8
    80004dd8:	def43823          	sd	a5,-528(s0)
    80004ddc:	008db503          	ld	a0,8(s11)
    80004de0:	c911                	beqz	a0,80004df4 <exec+0x226>
    if(argc >= MAXARG)
    80004de2:	09a1                	addi	s3,s3,8
    80004de4:	fb3c95e3          	bne	s9,s3,80004d8e <exec+0x1c0>
  sz = sz1;
    80004de8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dec:	4a81                	li	s5,0
    80004dee:	a84d                	j	80004ea0 <exec+0x2d2>
  sp = sz;
    80004df0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004df2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004df4:	00349793          	slli	a5,s1,0x3
    80004df8:	f9078793          	addi	a5,a5,-112 # f90 <_entry-0x7ffff070>
    80004dfc:	97a2                	add	a5,a5,s0
    80004dfe:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e02:	00148693          	addi	a3,s1,1
    80004e06:	068e                	slli	a3,a3,0x3
    80004e08:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e0c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e10:	01597663          	bgeu	s2,s5,80004e1c <exec+0x24e>
  sz = sz1;
    80004e14:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e18:	4a81                	li	s5,0
    80004e1a:	a059                	j	80004ea0 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e1c:	e9040613          	addi	a2,s0,-368
    80004e20:	85ca                	mv	a1,s2
    80004e22:	855a                	mv	a0,s6
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	836080e7          	jalr	-1994(ra) # 8000165a <copyout>
    80004e2c:	0a054663          	bltz	a0,80004ed8 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e30:	058bb783          	ld	a5,88(s7)
    80004e34:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e38:	de843783          	ld	a5,-536(s0)
    80004e3c:	0007c703          	lbu	a4,0(a5)
    80004e40:	cf11                	beqz	a4,80004e5c <exec+0x28e>
    80004e42:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e44:	02f00693          	li	a3,47
    80004e48:	a039                	j	80004e56 <exec+0x288>
      last = s+1;
    80004e4a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e4e:	0785                	addi	a5,a5,1
    80004e50:	fff7c703          	lbu	a4,-1(a5)
    80004e54:	c701                	beqz	a4,80004e5c <exec+0x28e>
    if(*s == '/')
    80004e56:	fed71ce3          	bne	a4,a3,80004e4e <exec+0x280>
    80004e5a:	bfc5                	j	80004e4a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e5c:	4641                	li	a2,16
    80004e5e:	de843583          	ld	a1,-536(s0)
    80004e62:	158b8513          	addi	a0,s7,344
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	fb0080e7          	jalr	-80(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e6e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e72:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e76:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e7a:	058bb783          	ld	a5,88(s7)
    80004e7e:	e6843703          	ld	a4,-408(s0)
    80004e82:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e84:	058bb783          	ld	a5,88(s7)
    80004e88:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e8c:	85ea                	mv	a1,s10
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	d0a080e7          	jalr	-758(ra) # 80001b98 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e96:	0004851b          	sext.w	a0,s1
    80004e9a:	bbc1                	j	80004c6a <exec+0x9c>
    80004e9c:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004ea0:	df843583          	ld	a1,-520(s0)
    80004ea4:	855a                	mv	a0,s6
    80004ea6:	ffffd097          	auipc	ra,0xffffd
    80004eaa:	cf2080e7          	jalr	-782(ra) # 80001b98 <proc_freepagetable>
  if(ip){
    80004eae:	da0a94e3          	bnez	s5,80004c56 <exec+0x88>
  return -1;
    80004eb2:	557d                	li	a0,-1
    80004eb4:	bb5d                	j	80004c6a <exec+0x9c>
    80004eb6:	de943c23          	sd	s1,-520(s0)
    80004eba:	b7dd                	j	80004ea0 <exec+0x2d2>
    80004ebc:	de943c23          	sd	s1,-520(s0)
    80004ec0:	b7c5                	j	80004ea0 <exec+0x2d2>
    80004ec2:	de943c23          	sd	s1,-520(s0)
    80004ec6:	bfe9                	j	80004ea0 <exec+0x2d2>
  sz = sz1;
    80004ec8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ecc:	4a81                	li	s5,0
    80004ece:	bfc9                	j	80004ea0 <exec+0x2d2>
  sz = sz1;
    80004ed0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ed4:	4a81                	li	s5,0
    80004ed6:	b7e9                	j	80004ea0 <exec+0x2d2>
  sz = sz1;
    80004ed8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004edc:	4a81                	li	s5,0
    80004ede:	b7c9                	j	80004ea0 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ee0:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ee4:	e0843783          	ld	a5,-504(s0)
    80004ee8:	0017869b          	addiw	a3,a5,1
    80004eec:	e0d43423          	sd	a3,-504(s0)
    80004ef0:	e0043783          	ld	a5,-512(s0)
    80004ef4:	0387879b          	addiw	a5,a5,56
    80004ef8:	e8845703          	lhu	a4,-376(s0)
    80004efc:	e2e6d3e3          	bge	a3,a4,80004d22 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f00:	2781                	sext.w	a5,a5
    80004f02:	e0f43023          	sd	a5,-512(s0)
    80004f06:	03800713          	li	a4,56
    80004f0a:	86be                	mv	a3,a5
    80004f0c:	e1840613          	addi	a2,s0,-488
    80004f10:	4581                	li	a1,0
    80004f12:	8556                	mv	a0,s5
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	a76080e7          	jalr	-1418(ra) # 8000398a <readi>
    80004f1c:	03800793          	li	a5,56
    80004f20:	f6f51ee3          	bne	a0,a5,80004e9c <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f24:	e1842783          	lw	a5,-488(s0)
    80004f28:	4705                	li	a4,1
    80004f2a:	fae79de3          	bne	a5,a4,80004ee4 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f2e:	e4043603          	ld	a2,-448(s0)
    80004f32:	e3843783          	ld	a5,-456(s0)
    80004f36:	f8f660e3          	bltu	a2,a5,80004eb6 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f3a:	e2843783          	ld	a5,-472(s0)
    80004f3e:	963e                	add	a2,a2,a5
    80004f40:	f6f66ee3          	bltu	a2,a5,80004ebc <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f44:	85a6                	mv	a1,s1
    80004f46:	855a                	mv	a0,s6
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	4be080e7          	jalr	1214(ra) # 80001406 <uvmalloc>
    80004f50:	dea43c23          	sd	a0,-520(s0)
    80004f54:	d53d                	beqz	a0,80004ec2 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80004f56:	e2843c03          	ld	s8,-472(s0)
    80004f5a:	de043783          	ld	a5,-544(s0)
    80004f5e:	00fc77b3          	and	a5,s8,a5
    80004f62:	ff9d                	bnez	a5,80004ea0 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f64:	e2042c83          	lw	s9,-480(s0)
    80004f68:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f6c:	f60b8ae3          	beqz	s7,80004ee0 <exec+0x312>
    80004f70:	89de                	mv	s3,s7
    80004f72:	4481                	li	s1,0
    80004f74:	b371                	j	80004d00 <exec+0x132>

0000000080004f76 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f76:	7179                	addi	sp,sp,-48
    80004f78:	f406                	sd	ra,40(sp)
    80004f7a:	f022                	sd	s0,32(sp)
    80004f7c:	ec26                	sd	s1,24(sp)
    80004f7e:	e84a                	sd	s2,16(sp)
    80004f80:	1800                	addi	s0,sp,48
    80004f82:	892e                	mv	s2,a1
    80004f84:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f86:	fdc40593          	addi	a1,s0,-36
    80004f8a:	ffffe097          	auipc	ra,0xffffe
    80004f8e:	b68080e7          	jalr	-1176(ra) # 80002af2 <argint>
    80004f92:	04054063          	bltz	a0,80004fd2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f96:	fdc42703          	lw	a4,-36(s0)
    80004f9a:	47bd                	li	a5,15
    80004f9c:	02e7ed63          	bltu	a5,a4,80004fd6 <argfd+0x60>
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	a6c080e7          	jalr	-1428(ra) # 80001a0c <myproc>
    80004fa8:	fdc42703          	lw	a4,-36(s0)
    80004fac:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004fb0:	078e                	slli	a5,a5,0x3
    80004fb2:	953e                	add	a0,a0,a5
    80004fb4:	611c                	ld	a5,0(a0)
    80004fb6:	c395                	beqz	a5,80004fda <argfd+0x64>
    return -1;
  if(pfd)
    80004fb8:	00090463          	beqz	s2,80004fc0 <argfd+0x4a>
    *pfd = fd;
    80004fbc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fc0:	4501                	li	a0,0
  if(pf)
    80004fc2:	c091                	beqz	s1,80004fc6 <argfd+0x50>
    *pf = f;
    80004fc4:	e09c                	sd	a5,0(s1)
}
    80004fc6:	70a2                	ld	ra,40(sp)
    80004fc8:	7402                	ld	s0,32(sp)
    80004fca:	64e2                	ld	s1,24(sp)
    80004fcc:	6942                	ld	s2,16(sp)
    80004fce:	6145                	addi	sp,sp,48
    80004fd0:	8082                	ret
    return -1;
    80004fd2:	557d                	li	a0,-1
    80004fd4:	bfcd                	j	80004fc6 <argfd+0x50>
    return -1;
    80004fd6:	557d                	li	a0,-1
    80004fd8:	b7fd                	j	80004fc6 <argfd+0x50>
    80004fda:	557d                	li	a0,-1
    80004fdc:	b7ed                	j	80004fc6 <argfd+0x50>

0000000080004fde <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fde:	1101                	addi	sp,sp,-32
    80004fe0:	ec06                	sd	ra,24(sp)
    80004fe2:	e822                	sd	s0,16(sp)
    80004fe4:	e426                	sd	s1,8(sp)
    80004fe6:	1000                	addi	s0,sp,32
    80004fe8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fea:	ffffd097          	auipc	ra,0xffffd
    80004fee:	a22080e7          	jalr	-1502(ra) # 80001a0c <myproc>
    80004ff2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004ff4:	0d050793          	addi	a5,a0,208
    80004ff8:	4501                	li	a0,0
    80004ffa:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ffc:	6398                	ld	a4,0(a5)
    80004ffe:	cb19                	beqz	a4,80005014 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005000:	2505                	addiw	a0,a0,1
    80005002:	07a1                	addi	a5,a5,8
    80005004:	fed51ce3          	bne	a0,a3,80004ffc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005008:	557d                	li	a0,-1
}
    8000500a:	60e2                	ld	ra,24(sp)
    8000500c:	6442                	ld	s0,16(sp)
    8000500e:	64a2                	ld	s1,8(sp)
    80005010:	6105                	addi	sp,sp,32
    80005012:	8082                	ret
      p->ofile[fd] = f;
    80005014:	01a50793          	addi	a5,a0,26
    80005018:	078e                	slli	a5,a5,0x3
    8000501a:	963e                	add	a2,a2,a5
    8000501c:	e204                	sd	s1,0(a2)
      return fd;
    8000501e:	b7f5                	j	8000500a <fdalloc+0x2c>

0000000080005020 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005020:	715d                	addi	sp,sp,-80
    80005022:	e486                	sd	ra,72(sp)
    80005024:	e0a2                	sd	s0,64(sp)
    80005026:	fc26                	sd	s1,56(sp)
    80005028:	f84a                	sd	s2,48(sp)
    8000502a:	f44e                	sd	s3,40(sp)
    8000502c:	f052                	sd	s4,32(sp)
    8000502e:	ec56                	sd	s5,24(sp)
    80005030:	0880                	addi	s0,sp,80
    80005032:	89ae                	mv	s3,a1
    80005034:	8ab2                	mv	s5,a2
    80005036:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005038:	fb040593          	addi	a1,s0,-80
    8000503c:	fffff097          	auipc	ra,0xfffff
    80005040:	e74080e7          	jalr	-396(ra) # 80003eb0 <nameiparent>
    80005044:	892a                	mv	s2,a0
    80005046:	12050e63          	beqz	a0,80005182 <create+0x162>
    return 0;

  ilock(dp);
    8000504a:	ffffe097          	auipc	ra,0xffffe
    8000504e:	68c080e7          	jalr	1676(ra) # 800036d6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005052:	4601                	li	a2,0
    80005054:	fb040593          	addi	a1,s0,-80
    80005058:	854a                	mv	a0,s2
    8000505a:	fffff097          	auipc	ra,0xfffff
    8000505e:	b60080e7          	jalr	-1184(ra) # 80003bba <dirlookup>
    80005062:	84aa                	mv	s1,a0
    80005064:	c921                	beqz	a0,800050b4 <create+0x94>
    iunlockput(dp);
    80005066:	854a                	mv	a0,s2
    80005068:	fffff097          	auipc	ra,0xfffff
    8000506c:	8d0080e7          	jalr	-1840(ra) # 80003938 <iunlockput>
    ilock(ip);
    80005070:	8526                	mv	a0,s1
    80005072:	ffffe097          	auipc	ra,0xffffe
    80005076:	664080e7          	jalr	1636(ra) # 800036d6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000507a:	2981                	sext.w	s3,s3
    8000507c:	4789                	li	a5,2
    8000507e:	02f99463          	bne	s3,a5,800050a6 <create+0x86>
    80005082:	0444d783          	lhu	a5,68(s1)
    80005086:	37f9                	addiw	a5,a5,-2
    80005088:	17c2                	slli	a5,a5,0x30
    8000508a:	93c1                	srli	a5,a5,0x30
    8000508c:	4705                	li	a4,1
    8000508e:	00f76c63          	bltu	a4,a5,800050a6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005092:	8526                	mv	a0,s1
    80005094:	60a6                	ld	ra,72(sp)
    80005096:	6406                	ld	s0,64(sp)
    80005098:	74e2                	ld	s1,56(sp)
    8000509a:	7942                	ld	s2,48(sp)
    8000509c:	79a2                	ld	s3,40(sp)
    8000509e:	7a02                	ld	s4,32(sp)
    800050a0:	6ae2                	ld	s5,24(sp)
    800050a2:	6161                	addi	sp,sp,80
    800050a4:	8082                	ret
    iunlockput(ip);
    800050a6:	8526                	mv	a0,s1
    800050a8:	fffff097          	auipc	ra,0xfffff
    800050ac:	890080e7          	jalr	-1904(ra) # 80003938 <iunlockput>
    return 0;
    800050b0:	4481                	li	s1,0
    800050b2:	b7c5                	j	80005092 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050b4:	85ce                	mv	a1,s3
    800050b6:	00092503          	lw	a0,0(s2)
    800050ba:	ffffe097          	auipc	ra,0xffffe
    800050be:	482080e7          	jalr	1154(ra) # 8000353c <ialloc>
    800050c2:	84aa                	mv	s1,a0
    800050c4:	c521                	beqz	a0,8000510c <create+0xec>
  ilock(ip);
    800050c6:	ffffe097          	auipc	ra,0xffffe
    800050ca:	610080e7          	jalr	1552(ra) # 800036d6 <ilock>
  ip->major = major;
    800050ce:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050d2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050d6:	4a05                	li	s4,1
    800050d8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800050dc:	8526                	mv	a0,s1
    800050de:	ffffe097          	auipc	ra,0xffffe
    800050e2:	52c080e7          	jalr	1324(ra) # 8000360a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050e6:	2981                	sext.w	s3,s3
    800050e8:	03498a63          	beq	s3,s4,8000511c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800050ec:	40d0                	lw	a2,4(s1)
    800050ee:	fb040593          	addi	a1,s0,-80
    800050f2:	854a                	mv	a0,s2
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	cdc080e7          	jalr	-804(ra) # 80003dd0 <dirlink>
    800050fc:	06054b63          	bltz	a0,80005172 <create+0x152>
  iunlockput(dp);
    80005100:	854a                	mv	a0,s2
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	836080e7          	jalr	-1994(ra) # 80003938 <iunlockput>
  return ip;
    8000510a:	b761                	j	80005092 <create+0x72>
    panic("create: ialloc");
    8000510c:	00003517          	auipc	a0,0x3
    80005110:	67c50513          	addi	a0,a0,1660 # 80008788 <syscalls+0x2c0>
    80005114:	ffffb097          	auipc	ra,0xffffb
    80005118:	426080e7          	jalr	1062(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    8000511c:	04a95783          	lhu	a5,74(s2)
    80005120:	2785                	addiw	a5,a5,1
    80005122:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005126:	854a                	mv	a0,s2
    80005128:	ffffe097          	auipc	ra,0xffffe
    8000512c:	4e2080e7          	jalr	1250(ra) # 8000360a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005130:	40d0                	lw	a2,4(s1)
    80005132:	00003597          	auipc	a1,0x3
    80005136:	66658593          	addi	a1,a1,1638 # 80008798 <syscalls+0x2d0>
    8000513a:	8526                	mv	a0,s1
    8000513c:	fffff097          	auipc	ra,0xfffff
    80005140:	c94080e7          	jalr	-876(ra) # 80003dd0 <dirlink>
    80005144:	00054f63          	bltz	a0,80005162 <create+0x142>
    80005148:	00492603          	lw	a2,4(s2)
    8000514c:	00003597          	auipc	a1,0x3
    80005150:	65458593          	addi	a1,a1,1620 # 800087a0 <syscalls+0x2d8>
    80005154:	8526                	mv	a0,s1
    80005156:	fffff097          	auipc	ra,0xfffff
    8000515a:	c7a080e7          	jalr	-902(ra) # 80003dd0 <dirlink>
    8000515e:	f80557e3          	bgez	a0,800050ec <create+0xcc>
      panic("create dots");
    80005162:	00003517          	auipc	a0,0x3
    80005166:	64650513          	addi	a0,a0,1606 # 800087a8 <syscalls+0x2e0>
    8000516a:	ffffb097          	auipc	ra,0xffffb
    8000516e:	3d0080e7          	jalr	976(ra) # 8000053a <panic>
    panic("create: dirlink");
    80005172:	00003517          	auipc	a0,0x3
    80005176:	64650513          	addi	a0,a0,1606 # 800087b8 <syscalls+0x2f0>
    8000517a:	ffffb097          	auipc	ra,0xffffb
    8000517e:	3c0080e7          	jalr	960(ra) # 8000053a <panic>
    return 0;
    80005182:	84aa                	mv	s1,a0
    80005184:	b739                	j	80005092 <create+0x72>

0000000080005186 <sys_dup>:
{
    80005186:	7179                	addi	sp,sp,-48
    80005188:	f406                	sd	ra,40(sp)
    8000518a:	f022                	sd	s0,32(sp)
    8000518c:	ec26                	sd	s1,24(sp)
    8000518e:	e84a                	sd	s2,16(sp)
    80005190:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005192:	fd840613          	addi	a2,s0,-40
    80005196:	4581                	li	a1,0
    80005198:	4501                	li	a0,0
    8000519a:	00000097          	auipc	ra,0x0
    8000519e:	ddc080e7          	jalr	-548(ra) # 80004f76 <argfd>
    return -1;
    800051a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051a4:	02054363          	bltz	a0,800051ca <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800051a8:	fd843903          	ld	s2,-40(s0)
    800051ac:	854a                	mv	a0,s2
    800051ae:	00000097          	auipc	ra,0x0
    800051b2:	e30080e7          	jalr	-464(ra) # 80004fde <fdalloc>
    800051b6:	84aa                	mv	s1,a0
    return -1;
    800051b8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051ba:	00054863          	bltz	a0,800051ca <sys_dup+0x44>
  filedup(f);
    800051be:	854a                	mv	a0,s2
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	368080e7          	jalr	872(ra) # 80004528 <filedup>
  return fd;
    800051c8:	87a6                	mv	a5,s1
}
    800051ca:	853e                	mv	a0,a5
    800051cc:	70a2                	ld	ra,40(sp)
    800051ce:	7402                	ld	s0,32(sp)
    800051d0:	64e2                	ld	s1,24(sp)
    800051d2:	6942                	ld	s2,16(sp)
    800051d4:	6145                	addi	sp,sp,48
    800051d6:	8082                	ret

00000000800051d8 <sys_read>:
{
    800051d8:	7179                	addi	sp,sp,-48
    800051da:	f406                	sd	ra,40(sp)
    800051dc:	f022                	sd	s0,32(sp)
    800051de:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e0:	fe840613          	addi	a2,s0,-24
    800051e4:	4581                	li	a1,0
    800051e6:	4501                	li	a0,0
    800051e8:	00000097          	auipc	ra,0x0
    800051ec:	d8e080e7          	jalr	-626(ra) # 80004f76 <argfd>
    return -1;
    800051f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f2:	04054163          	bltz	a0,80005234 <sys_read+0x5c>
    800051f6:	fe440593          	addi	a1,s0,-28
    800051fa:	4509                	li	a0,2
    800051fc:	ffffe097          	auipc	ra,0xffffe
    80005200:	8f6080e7          	jalr	-1802(ra) # 80002af2 <argint>
    return -1;
    80005204:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005206:	02054763          	bltz	a0,80005234 <sys_read+0x5c>
    8000520a:	fd840593          	addi	a1,s0,-40
    8000520e:	4505                	li	a0,1
    80005210:	ffffe097          	auipc	ra,0xffffe
    80005214:	904080e7          	jalr	-1788(ra) # 80002b14 <argaddr>
    return -1;
    80005218:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000521a:	00054d63          	bltz	a0,80005234 <sys_read+0x5c>
  return fileread(f, p, n);
    8000521e:	fe442603          	lw	a2,-28(s0)
    80005222:	fd843583          	ld	a1,-40(s0)
    80005226:	fe843503          	ld	a0,-24(s0)
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	48a080e7          	jalr	1162(ra) # 800046b4 <fileread>
    80005232:	87aa                	mv	a5,a0
}
    80005234:	853e                	mv	a0,a5
    80005236:	70a2                	ld	ra,40(sp)
    80005238:	7402                	ld	s0,32(sp)
    8000523a:	6145                	addi	sp,sp,48
    8000523c:	8082                	ret

000000008000523e <sys_write>:
{
    8000523e:	7179                	addi	sp,sp,-48
    80005240:	f406                	sd	ra,40(sp)
    80005242:	f022                	sd	s0,32(sp)
    80005244:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005246:	fe840613          	addi	a2,s0,-24
    8000524a:	4581                	li	a1,0
    8000524c:	4501                	li	a0,0
    8000524e:	00000097          	auipc	ra,0x0
    80005252:	d28080e7          	jalr	-728(ra) # 80004f76 <argfd>
    return -1;
    80005256:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005258:	04054163          	bltz	a0,8000529a <sys_write+0x5c>
    8000525c:	fe440593          	addi	a1,s0,-28
    80005260:	4509                	li	a0,2
    80005262:	ffffe097          	auipc	ra,0xffffe
    80005266:	890080e7          	jalr	-1904(ra) # 80002af2 <argint>
    return -1;
    8000526a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526c:	02054763          	bltz	a0,8000529a <sys_write+0x5c>
    80005270:	fd840593          	addi	a1,s0,-40
    80005274:	4505                	li	a0,1
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	89e080e7          	jalr	-1890(ra) # 80002b14 <argaddr>
    return -1;
    8000527e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005280:	00054d63          	bltz	a0,8000529a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005284:	fe442603          	lw	a2,-28(s0)
    80005288:	fd843583          	ld	a1,-40(s0)
    8000528c:	fe843503          	ld	a0,-24(s0)
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	4e6080e7          	jalr	1254(ra) # 80004776 <filewrite>
    80005298:	87aa                	mv	a5,a0
}
    8000529a:	853e                	mv	a0,a5
    8000529c:	70a2                	ld	ra,40(sp)
    8000529e:	7402                	ld	s0,32(sp)
    800052a0:	6145                	addi	sp,sp,48
    800052a2:	8082                	ret

00000000800052a4 <sys_close>:
{
    800052a4:	1101                	addi	sp,sp,-32
    800052a6:	ec06                	sd	ra,24(sp)
    800052a8:	e822                	sd	s0,16(sp)
    800052aa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052ac:	fe040613          	addi	a2,s0,-32
    800052b0:	fec40593          	addi	a1,s0,-20
    800052b4:	4501                	li	a0,0
    800052b6:	00000097          	auipc	ra,0x0
    800052ba:	cc0080e7          	jalr	-832(ra) # 80004f76 <argfd>
    return -1;
    800052be:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052c0:	02054463          	bltz	a0,800052e8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052c4:	ffffc097          	auipc	ra,0xffffc
    800052c8:	748080e7          	jalr	1864(ra) # 80001a0c <myproc>
    800052cc:	fec42783          	lw	a5,-20(s0)
    800052d0:	07e9                	addi	a5,a5,26
    800052d2:	078e                	slli	a5,a5,0x3
    800052d4:	953e                	add	a0,a0,a5
    800052d6:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800052da:	fe043503          	ld	a0,-32(s0)
    800052de:	fffff097          	auipc	ra,0xfffff
    800052e2:	29c080e7          	jalr	668(ra) # 8000457a <fileclose>
  return 0;
    800052e6:	4781                	li	a5,0
}
    800052e8:	853e                	mv	a0,a5
    800052ea:	60e2                	ld	ra,24(sp)
    800052ec:	6442                	ld	s0,16(sp)
    800052ee:	6105                	addi	sp,sp,32
    800052f0:	8082                	ret

00000000800052f2 <sys_fstat>:
{
    800052f2:	1101                	addi	sp,sp,-32
    800052f4:	ec06                	sd	ra,24(sp)
    800052f6:	e822                	sd	s0,16(sp)
    800052f8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052fa:	fe840613          	addi	a2,s0,-24
    800052fe:	4581                	li	a1,0
    80005300:	4501                	li	a0,0
    80005302:	00000097          	auipc	ra,0x0
    80005306:	c74080e7          	jalr	-908(ra) # 80004f76 <argfd>
    return -1;
    8000530a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000530c:	02054563          	bltz	a0,80005336 <sys_fstat+0x44>
    80005310:	fe040593          	addi	a1,s0,-32
    80005314:	4505                	li	a0,1
    80005316:	ffffd097          	auipc	ra,0xffffd
    8000531a:	7fe080e7          	jalr	2046(ra) # 80002b14 <argaddr>
    return -1;
    8000531e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005320:	00054b63          	bltz	a0,80005336 <sys_fstat+0x44>
  return filestat(f, st);
    80005324:	fe043583          	ld	a1,-32(s0)
    80005328:	fe843503          	ld	a0,-24(s0)
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	316080e7          	jalr	790(ra) # 80004642 <filestat>
    80005334:	87aa                	mv	a5,a0
}
    80005336:	853e                	mv	a0,a5
    80005338:	60e2                	ld	ra,24(sp)
    8000533a:	6442                	ld	s0,16(sp)
    8000533c:	6105                	addi	sp,sp,32
    8000533e:	8082                	ret

0000000080005340 <sys_link>:
{
    80005340:	7169                	addi	sp,sp,-304
    80005342:	f606                	sd	ra,296(sp)
    80005344:	f222                	sd	s0,288(sp)
    80005346:	ee26                	sd	s1,280(sp)
    80005348:	ea4a                	sd	s2,272(sp)
    8000534a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000534c:	08000613          	li	a2,128
    80005350:	ed040593          	addi	a1,s0,-304
    80005354:	4501                	li	a0,0
    80005356:	ffffd097          	auipc	ra,0xffffd
    8000535a:	7e0080e7          	jalr	2016(ra) # 80002b36 <argstr>
    return -1;
    8000535e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005360:	10054e63          	bltz	a0,8000547c <sys_link+0x13c>
    80005364:	08000613          	li	a2,128
    80005368:	f5040593          	addi	a1,s0,-176
    8000536c:	4505                	li	a0,1
    8000536e:	ffffd097          	auipc	ra,0xffffd
    80005372:	7c8080e7          	jalr	1992(ra) # 80002b36 <argstr>
    return -1;
    80005376:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005378:	10054263          	bltz	a0,8000547c <sys_link+0x13c>
  begin_op();
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	d36080e7          	jalr	-714(ra) # 800040b2 <begin_op>
  if((ip = namei(old)) == 0){
    80005384:	ed040513          	addi	a0,s0,-304
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	b0a080e7          	jalr	-1270(ra) # 80003e92 <namei>
    80005390:	84aa                	mv	s1,a0
    80005392:	c551                	beqz	a0,8000541e <sys_link+0xde>
  ilock(ip);
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	342080e7          	jalr	834(ra) # 800036d6 <ilock>
  if(ip->type == T_DIR){
    8000539c:	04449703          	lh	a4,68(s1)
    800053a0:	4785                	li	a5,1
    800053a2:	08f70463          	beq	a4,a5,8000542a <sys_link+0xea>
  ip->nlink++;
    800053a6:	04a4d783          	lhu	a5,74(s1)
    800053aa:	2785                	addiw	a5,a5,1
    800053ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053b0:	8526                	mv	a0,s1
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	258080e7          	jalr	600(ra) # 8000360a <iupdate>
  iunlock(ip);
    800053ba:	8526                	mv	a0,s1
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	3dc080e7          	jalr	988(ra) # 80003798 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053c4:	fd040593          	addi	a1,s0,-48
    800053c8:	f5040513          	addi	a0,s0,-176
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	ae4080e7          	jalr	-1308(ra) # 80003eb0 <nameiparent>
    800053d4:	892a                	mv	s2,a0
    800053d6:	c935                	beqz	a0,8000544a <sys_link+0x10a>
  ilock(dp);
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	2fe080e7          	jalr	766(ra) # 800036d6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053e0:	00092703          	lw	a4,0(s2)
    800053e4:	409c                	lw	a5,0(s1)
    800053e6:	04f71d63          	bne	a4,a5,80005440 <sys_link+0x100>
    800053ea:	40d0                	lw	a2,4(s1)
    800053ec:	fd040593          	addi	a1,s0,-48
    800053f0:	854a                	mv	a0,s2
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	9de080e7          	jalr	-1570(ra) # 80003dd0 <dirlink>
    800053fa:	04054363          	bltz	a0,80005440 <sys_link+0x100>
  iunlockput(dp);
    800053fe:	854a                	mv	a0,s2
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	538080e7          	jalr	1336(ra) # 80003938 <iunlockput>
  iput(ip);
    80005408:	8526                	mv	a0,s1
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	486080e7          	jalr	1158(ra) # 80003890 <iput>
  end_op();
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	d1e080e7          	jalr	-738(ra) # 80004130 <end_op>
  return 0;
    8000541a:	4781                	li	a5,0
    8000541c:	a085                	j	8000547c <sys_link+0x13c>
    end_op();
    8000541e:	fffff097          	auipc	ra,0xfffff
    80005422:	d12080e7          	jalr	-750(ra) # 80004130 <end_op>
    return -1;
    80005426:	57fd                	li	a5,-1
    80005428:	a891                	j	8000547c <sys_link+0x13c>
    iunlockput(ip);
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	50c080e7          	jalr	1292(ra) # 80003938 <iunlockput>
    end_op();
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	cfc080e7          	jalr	-772(ra) # 80004130 <end_op>
    return -1;
    8000543c:	57fd                	li	a5,-1
    8000543e:	a83d                	j	8000547c <sys_link+0x13c>
    iunlockput(dp);
    80005440:	854a                	mv	a0,s2
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	4f6080e7          	jalr	1270(ra) # 80003938 <iunlockput>
  ilock(ip);
    8000544a:	8526                	mv	a0,s1
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	28a080e7          	jalr	650(ra) # 800036d6 <ilock>
  ip->nlink--;
    80005454:	04a4d783          	lhu	a5,74(s1)
    80005458:	37fd                	addiw	a5,a5,-1
    8000545a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000545e:	8526                	mv	a0,s1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	1aa080e7          	jalr	426(ra) # 8000360a <iupdate>
  iunlockput(ip);
    80005468:	8526                	mv	a0,s1
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	4ce080e7          	jalr	1230(ra) # 80003938 <iunlockput>
  end_op();
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	cbe080e7          	jalr	-834(ra) # 80004130 <end_op>
  return -1;
    8000547a:	57fd                	li	a5,-1
}
    8000547c:	853e                	mv	a0,a5
    8000547e:	70b2                	ld	ra,296(sp)
    80005480:	7412                	ld	s0,288(sp)
    80005482:	64f2                	ld	s1,280(sp)
    80005484:	6952                	ld	s2,272(sp)
    80005486:	6155                	addi	sp,sp,304
    80005488:	8082                	ret

000000008000548a <sys_unlink>:
{
    8000548a:	7151                	addi	sp,sp,-240
    8000548c:	f586                	sd	ra,232(sp)
    8000548e:	f1a2                	sd	s0,224(sp)
    80005490:	eda6                	sd	s1,216(sp)
    80005492:	e9ca                	sd	s2,208(sp)
    80005494:	e5ce                	sd	s3,200(sp)
    80005496:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005498:	08000613          	li	a2,128
    8000549c:	f3040593          	addi	a1,s0,-208
    800054a0:	4501                	li	a0,0
    800054a2:	ffffd097          	auipc	ra,0xffffd
    800054a6:	694080e7          	jalr	1684(ra) # 80002b36 <argstr>
    800054aa:	18054163          	bltz	a0,8000562c <sys_unlink+0x1a2>
  begin_op();
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	c04080e7          	jalr	-1020(ra) # 800040b2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054b6:	fb040593          	addi	a1,s0,-80
    800054ba:	f3040513          	addi	a0,s0,-208
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	9f2080e7          	jalr	-1550(ra) # 80003eb0 <nameiparent>
    800054c6:	84aa                	mv	s1,a0
    800054c8:	c979                	beqz	a0,8000559e <sys_unlink+0x114>
  ilock(dp);
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	20c080e7          	jalr	524(ra) # 800036d6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054d2:	00003597          	auipc	a1,0x3
    800054d6:	2c658593          	addi	a1,a1,710 # 80008798 <syscalls+0x2d0>
    800054da:	fb040513          	addi	a0,s0,-80
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	6c2080e7          	jalr	1730(ra) # 80003ba0 <namecmp>
    800054e6:	14050a63          	beqz	a0,8000563a <sys_unlink+0x1b0>
    800054ea:	00003597          	auipc	a1,0x3
    800054ee:	2b658593          	addi	a1,a1,694 # 800087a0 <syscalls+0x2d8>
    800054f2:	fb040513          	addi	a0,s0,-80
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	6aa080e7          	jalr	1706(ra) # 80003ba0 <namecmp>
    800054fe:	12050e63          	beqz	a0,8000563a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005502:	f2c40613          	addi	a2,s0,-212
    80005506:	fb040593          	addi	a1,s0,-80
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	6ae080e7          	jalr	1710(ra) # 80003bba <dirlookup>
    80005514:	892a                	mv	s2,a0
    80005516:	12050263          	beqz	a0,8000563a <sys_unlink+0x1b0>
  ilock(ip);
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	1bc080e7          	jalr	444(ra) # 800036d6 <ilock>
  if(ip->nlink < 1)
    80005522:	04a91783          	lh	a5,74(s2)
    80005526:	08f05263          	blez	a5,800055aa <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000552a:	04491703          	lh	a4,68(s2)
    8000552e:	4785                	li	a5,1
    80005530:	08f70563          	beq	a4,a5,800055ba <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005534:	4641                	li	a2,16
    80005536:	4581                	li	a1,0
    80005538:	fc040513          	addi	a0,s0,-64
    8000553c:	ffffb097          	auipc	ra,0xffffb
    80005540:	790080e7          	jalr	1936(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005544:	4741                	li	a4,16
    80005546:	f2c42683          	lw	a3,-212(s0)
    8000554a:	fc040613          	addi	a2,s0,-64
    8000554e:	4581                	li	a1,0
    80005550:	8526                	mv	a0,s1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	530080e7          	jalr	1328(ra) # 80003a82 <writei>
    8000555a:	47c1                	li	a5,16
    8000555c:	0af51563          	bne	a0,a5,80005606 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005560:	04491703          	lh	a4,68(s2)
    80005564:	4785                	li	a5,1
    80005566:	0af70863          	beq	a4,a5,80005616 <sys_unlink+0x18c>
  iunlockput(dp);
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	3cc080e7          	jalr	972(ra) # 80003938 <iunlockput>
  ip->nlink--;
    80005574:	04a95783          	lhu	a5,74(s2)
    80005578:	37fd                	addiw	a5,a5,-1
    8000557a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000557e:	854a                	mv	a0,s2
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	08a080e7          	jalr	138(ra) # 8000360a <iupdate>
  iunlockput(ip);
    80005588:	854a                	mv	a0,s2
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	3ae080e7          	jalr	942(ra) # 80003938 <iunlockput>
  end_op();
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	b9e080e7          	jalr	-1122(ra) # 80004130 <end_op>
  return 0;
    8000559a:	4501                	li	a0,0
    8000559c:	a84d                	j	8000564e <sys_unlink+0x1c4>
    end_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	b92080e7          	jalr	-1134(ra) # 80004130 <end_op>
    return -1;
    800055a6:	557d                	li	a0,-1
    800055a8:	a05d                	j	8000564e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055aa:	00003517          	auipc	a0,0x3
    800055ae:	21e50513          	addi	a0,a0,542 # 800087c8 <syscalls+0x300>
    800055b2:	ffffb097          	auipc	ra,0xffffb
    800055b6:	f88080e7          	jalr	-120(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ba:	04c92703          	lw	a4,76(s2)
    800055be:	02000793          	li	a5,32
    800055c2:	f6e7f9e3          	bgeu	a5,a4,80005534 <sys_unlink+0xaa>
    800055c6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ca:	4741                	li	a4,16
    800055cc:	86ce                	mv	a3,s3
    800055ce:	f1840613          	addi	a2,s0,-232
    800055d2:	4581                	li	a1,0
    800055d4:	854a                	mv	a0,s2
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	3b4080e7          	jalr	948(ra) # 8000398a <readi>
    800055de:	47c1                	li	a5,16
    800055e0:	00f51b63          	bne	a0,a5,800055f6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055e4:	f1845783          	lhu	a5,-232(s0)
    800055e8:	e7a1                	bnez	a5,80005630 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ea:	29c1                	addiw	s3,s3,16
    800055ec:	04c92783          	lw	a5,76(s2)
    800055f0:	fcf9ede3          	bltu	s3,a5,800055ca <sys_unlink+0x140>
    800055f4:	b781                	j	80005534 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055f6:	00003517          	auipc	a0,0x3
    800055fa:	1ea50513          	addi	a0,a0,490 # 800087e0 <syscalls+0x318>
    800055fe:	ffffb097          	auipc	ra,0xffffb
    80005602:	f3c080e7          	jalr	-196(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005606:	00003517          	auipc	a0,0x3
    8000560a:	1f250513          	addi	a0,a0,498 # 800087f8 <syscalls+0x330>
    8000560e:	ffffb097          	auipc	ra,0xffffb
    80005612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
    dp->nlink--;
    80005616:	04a4d783          	lhu	a5,74(s1)
    8000561a:	37fd                	addiw	a5,a5,-1
    8000561c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005620:	8526                	mv	a0,s1
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	fe8080e7          	jalr	-24(ra) # 8000360a <iupdate>
    8000562a:	b781                	j	8000556a <sys_unlink+0xe0>
    return -1;
    8000562c:	557d                	li	a0,-1
    8000562e:	a005                	j	8000564e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005630:	854a                	mv	a0,s2
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	306080e7          	jalr	774(ra) # 80003938 <iunlockput>
  iunlockput(dp);
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	2fc080e7          	jalr	764(ra) # 80003938 <iunlockput>
  end_op();
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	aec080e7          	jalr	-1300(ra) # 80004130 <end_op>
  return -1;
    8000564c:	557d                	li	a0,-1
}
    8000564e:	70ae                	ld	ra,232(sp)
    80005650:	740e                	ld	s0,224(sp)
    80005652:	64ee                	ld	s1,216(sp)
    80005654:	694e                	ld	s2,208(sp)
    80005656:	69ae                	ld	s3,200(sp)
    80005658:	616d                	addi	sp,sp,240
    8000565a:	8082                	ret

000000008000565c <sys_open>:

uint64
sys_open(void)
{
    8000565c:	7131                	addi	sp,sp,-192
    8000565e:	fd06                	sd	ra,184(sp)
    80005660:	f922                	sd	s0,176(sp)
    80005662:	f526                	sd	s1,168(sp)
    80005664:	f14a                	sd	s2,160(sp)
    80005666:	ed4e                	sd	s3,152(sp)
    80005668:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000566a:	08000613          	li	a2,128
    8000566e:	f5040593          	addi	a1,s0,-176
    80005672:	4501                	li	a0,0
    80005674:	ffffd097          	auipc	ra,0xffffd
    80005678:	4c2080e7          	jalr	1218(ra) # 80002b36 <argstr>
    return -1;
    8000567c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000567e:	0c054163          	bltz	a0,80005740 <sys_open+0xe4>
    80005682:	f4c40593          	addi	a1,s0,-180
    80005686:	4505                	li	a0,1
    80005688:	ffffd097          	auipc	ra,0xffffd
    8000568c:	46a080e7          	jalr	1130(ra) # 80002af2 <argint>
    80005690:	0a054863          	bltz	a0,80005740 <sys_open+0xe4>

  begin_op();
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	a1e080e7          	jalr	-1506(ra) # 800040b2 <begin_op>

  if(omode & O_CREATE){
    8000569c:	f4c42783          	lw	a5,-180(s0)
    800056a0:	2007f793          	andi	a5,a5,512
    800056a4:	cbdd                	beqz	a5,8000575a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056a6:	4681                	li	a3,0
    800056a8:	4601                	li	a2,0
    800056aa:	4589                	li	a1,2
    800056ac:	f5040513          	addi	a0,s0,-176
    800056b0:	00000097          	auipc	ra,0x0
    800056b4:	970080e7          	jalr	-1680(ra) # 80005020 <create>
    800056b8:	892a                	mv	s2,a0
    if(ip == 0){
    800056ba:	c959                	beqz	a0,80005750 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056bc:	04491703          	lh	a4,68(s2)
    800056c0:	478d                	li	a5,3
    800056c2:	00f71763          	bne	a4,a5,800056d0 <sys_open+0x74>
    800056c6:	04695703          	lhu	a4,70(s2)
    800056ca:	47a5                	li	a5,9
    800056cc:	0ce7ec63          	bltu	a5,a4,800057a4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	dee080e7          	jalr	-530(ra) # 800044be <filealloc>
    800056d8:	89aa                	mv	s3,a0
    800056da:	10050263          	beqz	a0,800057de <sys_open+0x182>
    800056de:	00000097          	auipc	ra,0x0
    800056e2:	900080e7          	jalr	-1792(ra) # 80004fde <fdalloc>
    800056e6:	84aa                	mv	s1,a0
    800056e8:	0e054663          	bltz	a0,800057d4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056ec:	04491703          	lh	a4,68(s2)
    800056f0:	478d                	li	a5,3
    800056f2:	0cf70463          	beq	a4,a5,800057ba <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056f6:	4789                	li	a5,2
    800056f8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056fc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005700:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005704:	f4c42783          	lw	a5,-180(s0)
    80005708:	0017c713          	xori	a4,a5,1
    8000570c:	8b05                	andi	a4,a4,1
    8000570e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005712:	0037f713          	andi	a4,a5,3
    80005716:	00e03733          	snez	a4,a4
    8000571a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000571e:	4007f793          	andi	a5,a5,1024
    80005722:	c791                	beqz	a5,8000572e <sys_open+0xd2>
    80005724:	04491703          	lh	a4,68(s2)
    80005728:	4789                	li	a5,2
    8000572a:	08f70f63          	beq	a4,a5,800057c8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000572e:	854a                	mv	a0,s2
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	068080e7          	jalr	104(ra) # 80003798 <iunlock>
  end_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	9f8080e7          	jalr	-1544(ra) # 80004130 <end_op>

  return fd;
}
    80005740:	8526                	mv	a0,s1
    80005742:	70ea                	ld	ra,184(sp)
    80005744:	744a                	ld	s0,176(sp)
    80005746:	74aa                	ld	s1,168(sp)
    80005748:	790a                	ld	s2,160(sp)
    8000574a:	69ea                	ld	s3,152(sp)
    8000574c:	6129                	addi	sp,sp,192
    8000574e:	8082                	ret
      end_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	9e0080e7          	jalr	-1568(ra) # 80004130 <end_op>
      return -1;
    80005758:	b7e5                	j	80005740 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000575a:	f5040513          	addi	a0,s0,-176
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	734080e7          	jalr	1844(ra) # 80003e92 <namei>
    80005766:	892a                	mv	s2,a0
    80005768:	c905                	beqz	a0,80005798 <sys_open+0x13c>
    ilock(ip);
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	f6c080e7          	jalr	-148(ra) # 800036d6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005772:	04491703          	lh	a4,68(s2)
    80005776:	4785                	li	a5,1
    80005778:	f4f712e3          	bne	a4,a5,800056bc <sys_open+0x60>
    8000577c:	f4c42783          	lw	a5,-180(s0)
    80005780:	dba1                	beqz	a5,800056d0 <sys_open+0x74>
      iunlockput(ip);
    80005782:	854a                	mv	a0,s2
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	1b4080e7          	jalr	436(ra) # 80003938 <iunlockput>
      end_op();
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	9a4080e7          	jalr	-1628(ra) # 80004130 <end_op>
      return -1;
    80005794:	54fd                	li	s1,-1
    80005796:	b76d                	j	80005740 <sys_open+0xe4>
      end_op();
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	998080e7          	jalr	-1640(ra) # 80004130 <end_op>
      return -1;
    800057a0:	54fd                	li	s1,-1
    800057a2:	bf79                	j	80005740 <sys_open+0xe4>
    iunlockput(ip);
    800057a4:	854a                	mv	a0,s2
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	192080e7          	jalr	402(ra) # 80003938 <iunlockput>
    end_op();
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	982080e7          	jalr	-1662(ra) # 80004130 <end_op>
    return -1;
    800057b6:	54fd                	li	s1,-1
    800057b8:	b761                	j	80005740 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057ba:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057be:	04691783          	lh	a5,70(s2)
    800057c2:	02f99223          	sh	a5,36(s3)
    800057c6:	bf2d                	j	80005700 <sys_open+0xa4>
    itrunc(ip);
    800057c8:	854a                	mv	a0,s2
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	01a080e7          	jalr	26(ra) # 800037e4 <itrunc>
    800057d2:	bfb1                	j	8000572e <sys_open+0xd2>
      fileclose(f);
    800057d4:	854e                	mv	a0,s3
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	da4080e7          	jalr	-604(ra) # 8000457a <fileclose>
    iunlockput(ip);
    800057de:	854a                	mv	a0,s2
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	158080e7          	jalr	344(ra) # 80003938 <iunlockput>
    end_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	948080e7          	jalr	-1720(ra) # 80004130 <end_op>
    return -1;
    800057f0:	54fd                	li	s1,-1
    800057f2:	b7b9                	j	80005740 <sys_open+0xe4>

00000000800057f4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057f4:	7175                	addi	sp,sp,-144
    800057f6:	e506                	sd	ra,136(sp)
    800057f8:	e122                	sd	s0,128(sp)
    800057fa:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	8b6080e7          	jalr	-1866(ra) # 800040b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005804:	08000613          	li	a2,128
    80005808:	f7040593          	addi	a1,s0,-144
    8000580c:	4501                	li	a0,0
    8000580e:	ffffd097          	auipc	ra,0xffffd
    80005812:	328080e7          	jalr	808(ra) # 80002b36 <argstr>
    80005816:	02054963          	bltz	a0,80005848 <sys_mkdir+0x54>
    8000581a:	4681                	li	a3,0
    8000581c:	4601                	li	a2,0
    8000581e:	4585                	li	a1,1
    80005820:	f7040513          	addi	a0,s0,-144
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	7fc080e7          	jalr	2044(ra) # 80005020 <create>
    8000582c:	cd11                	beqz	a0,80005848 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	10a080e7          	jalr	266(ra) # 80003938 <iunlockput>
  end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	8fa080e7          	jalr	-1798(ra) # 80004130 <end_op>
  return 0;
    8000583e:	4501                	li	a0,0
}
    80005840:	60aa                	ld	ra,136(sp)
    80005842:	640a                	ld	s0,128(sp)
    80005844:	6149                	addi	sp,sp,144
    80005846:	8082                	ret
    end_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	8e8080e7          	jalr	-1816(ra) # 80004130 <end_op>
    return -1;
    80005850:	557d                	li	a0,-1
    80005852:	b7fd                	j	80005840 <sys_mkdir+0x4c>

0000000080005854 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005854:	7135                	addi	sp,sp,-160
    80005856:	ed06                	sd	ra,152(sp)
    80005858:	e922                	sd	s0,144(sp)
    8000585a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	856080e7          	jalr	-1962(ra) # 800040b2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005864:	08000613          	li	a2,128
    80005868:	f7040593          	addi	a1,s0,-144
    8000586c:	4501                	li	a0,0
    8000586e:	ffffd097          	auipc	ra,0xffffd
    80005872:	2c8080e7          	jalr	712(ra) # 80002b36 <argstr>
    80005876:	04054a63          	bltz	a0,800058ca <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000587a:	f6c40593          	addi	a1,s0,-148
    8000587e:	4505                	li	a0,1
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	272080e7          	jalr	626(ra) # 80002af2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005888:	04054163          	bltz	a0,800058ca <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000588c:	f6840593          	addi	a1,s0,-152
    80005890:	4509                	li	a0,2
    80005892:	ffffd097          	auipc	ra,0xffffd
    80005896:	260080e7          	jalr	608(ra) # 80002af2 <argint>
     argint(1, &major) < 0 ||
    8000589a:	02054863          	bltz	a0,800058ca <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000589e:	f6841683          	lh	a3,-152(s0)
    800058a2:	f6c41603          	lh	a2,-148(s0)
    800058a6:	458d                	li	a1,3
    800058a8:	f7040513          	addi	a0,s0,-144
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	774080e7          	jalr	1908(ra) # 80005020 <create>
     argint(2, &minor) < 0 ||
    800058b4:	c919                	beqz	a0,800058ca <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	082080e7          	jalr	130(ra) # 80003938 <iunlockput>
  end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	872080e7          	jalr	-1934(ra) # 80004130 <end_op>
  return 0;
    800058c6:	4501                	li	a0,0
    800058c8:	a031                	j	800058d4 <sys_mknod+0x80>
    end_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	866080e7          	jalr	-1946(ra) # 80004130 <end_op>
    return -1;
    800058d2:	557d                	li	a0,-1
}
    800058d4:	60ea                	ld	ra,152(sp)
    800058d6:	644a                	ld	s0,144(sp)
    800058d8:	610d                	addi	sp,sp,160
    800058da:	8082                	ret

00000000800058dc <sys_chdir>:

uint64
sys_chdir(void)
{
    800058dc:	7135                	addi	sp,sp,-160
    800058de:	ed06                	sd	ra,152(sp)
    800058e0:	e922                	sd	s0,144(sp)
    800058e2:	e526                	sd	s1,136(sp)
    800058e4:	e14a                	sd	s2,128(sp)
    800058e6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058e8:	ffffc097          	auipc	ra,0xffffc
    800058ec:	124080e7          	jalr	292(ra) # 80001a0c <myproc>
    800058f0:	892a                	mv	s2,a0
  
  begin_op();
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	7c0080e7          	jalr	1984(ra) # 800040b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058fa:	08000613          	li	a2,128
    800058fe:	f6040593          	addi	a1,s0,-160
    80005902:	4501                	li	a0,0
    80005904:	ffffd097          	auipc	ra,0xffffd
    80005908:	232080e7          	jalr	562(ra) # 80002b36 <argstr>
    8000590c:	04054b63          	bltz	a0,80005962 <sys_chdir+0x86>
    80005910:	f6040513          	addi	a0,s0,-160
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	57e080e7          	jalr	1406(ra) # 80003e92 <namei>
    8000591c:	84aa                	mv	s1,a0
    8000591e:	c131                	beqz	a0,80005962 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	db6080e7          	jalr	-586(ra) # 800036d6 <ilock>
  if(ip->type != T_DIR){
    80005928:	04449703          	lh	a4,68(s1)
    8000592c:	4785                	li	a5,1
    8000592e:	04f71063          	bne	a4,a5,8000596e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005932:	8526                	mv	a0,s1
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	e64080e7          	jalr	-412(ra) # 80003798 <iunlock>
  iput(p->cwd);
    8000593c:	15093503          	ld	a0,336(s2)
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	f50080e7          	jalr	-176(ra) # 80003890 <iput>
  end_op();
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	7e8080e7          	jalr	2024(ra) # 80004130 <end_op>
  p->cwd = ip;
    80005950:	14993823          	sd	s1,336(s2)
  return 0;
    80005954:	4501                	li	a0,0
}
    80005956:	60ea                	ld	ra,152(sp)
    80005958:	644a                	ld	s0,144(sp)
    8000595a:	64aa                	ld	s1,136(sp)
    8000595c:	690a                	ld	s2,128(sp)
    8000595e:	610d                	addi	sp,sp,160
    80005960:	8082                	ret
    end_op();
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	7ce080e7          	jalr	1998(ra) # 80004130 <end_op>
    return -1;
    8000596a:	557d                	li	a0,-1
    8000596c:	b7ed                	j	80005956 <sys_chdir+0x7a>
    iunlockput(ip);
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	fc8080e7          	jalr	-56(ra) # 80003938 <iunlockput>
    end_op();
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	7b8080e7          	jalr	1976(ra) # 80004130 <end_op>
    return -1;
    80005980:	557d                	li	a0,-1
    80005982:	bfd1                	j	80005956 <sys_chdir+0x7a>

0000000080005984 <sys_exec>:

uint64
sys_exec(void)
{
    80005984:	7145                	addi	sp,sp,-464
    80005986:	e786                	sd	ra,456(sp)
    80005988:	e3a2                	sd	s0,448(sp)
    8000598a:	ff26                	sd	s1,440(sp)
    8000598c:	fb4a                	sd	s2,432(sp)
    8000598e:	f74e                	sd	s3,424(sp)
    80005990:	f352                	sd	s4,416(sp)
    80005992:	ef56                	sd	s5,408(sp)
    80005994:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005996:	08000613          	li	a2,128
    8000599a:	f4040593          	addi	a1,s0,-192
    8000599e:	4501                	li	a0,0
    800059a0:	ffffd097          	auipc	ra,0xffffd
    800059a4:	196080e7          	jalr	406(ra) # 80002b36 <argstr>
    return -1;
    800059a8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059aa:	0c054b63          	bltz	a0,80005a80 <sys_exec+0xfc>
    800059ae:	e3840593          	addi	a1,s0,-456
    800059b2:	4505                	li	a0,1
    800059b4:	ffffd097          	auipc	ra,0xffffd
    800059b8:	160080e7          	jalr	352(ra) # 80002b14 <argaddr>
    800059bc:	0c054263          	bltz	a0,80005a80 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800059c0:	10000613          	li	a2,256
    800059c4:	4581                	li	a1,0
    800059c6:	e4040513          	addi	a0,s0,-448
    800059ca:	ffffb097          	auipc	ra,0xffffb
    800059ce:	302080e7          	jalr	770(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059d2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059d6:	89a6                	mv	s3,s1
    800059d8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059da:	02000a13          	li	s4,32
    800059de:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059e2:	00391513          	slli	a0,s2,0x3
    800059e6:	e3040593          	addi	a1,s0,-464
    800059ea:	e3843783          	ld	a5,-456(s0)
    800059ee:	953e                	add	a0,a0,a5
    800059f0:	ffffd097          	auipc	ra,0xffffd
    800059f4:	068080e7          	jalr	104(ra) # 80002a58 <fetchaddr>
    800059f8:	02054a63          	bltz	a0,80005a2c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059fc:	e3043783          	ld	a5,-464(s0)
    80005a00:	c3b9                	beqz	a5,80005a46 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a02:	ffffb097          	auipc	ra,0xffffb
    80005a06:	0de080e7          	jalr	222(ra) # 80000ae0 <kalloc>
    80005a0a:	85aa                	mv	a1,a0
    80005a0c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a10:	cd11                	beqz	a0,80005a2c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a12:	6605                	lui	a2,0x1
    80005a14:	e3043503          	ld	a0,-464(s0)
    80005a18:	ffffd097          	auipc	ra,0xffffd
    80005a1c:	092080e7          	jalr	146(ra) # 80002aaa <fetchstr>
    80005a20:	00054663          	bltz	a0,80005a2c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a24:	0905                	addi	s2,s2,1
    80005a26:	09a1                	addi	s3,s3,8
    80005a28:	fb491be3          	bne	s2,s4,800059de <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a2c:	f4040913          	addi	s2,s0,-192
    80005a30:	6088                	ld	a0,0(s1)
    80005a32:	c531                	beqz	a0,80005a7e <sys_exec+0xfa>
    kfree(argv[i]);
    80005a34:	ffffb097          	auipc	ra,0xffffb
    80005a38:	fae080e7          	jalr	-82(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a3c:	04a1                	addi	s1,s1,8
    80005a3e:	ff2499e3          	bne	s1,s2,80005a30 <sys_exec+0xac>
  return -1;
    80005a42:	597d                	li	s2,-1
    80005a44:	a835                	j	80005a80 <sys_exec+0xfc>
      argv[i] = 0;
    80005a46:	0a8e                	slli	s5,s5,0x3
    80005a48:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005a4c:	00878ab3          	add	s5,a5,s0
    80005a50:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a54:	e4040593          	addi	a1,s0,-448
    80005a58:	f4040513          	addi	a0,s0,-192
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	172080e7          	jalr	370(ra) # 80004bce <exec>
    80005a64:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a66:	f4040993          	addi	s3,s0,-192
    80005a6a:	6088                	ld	a0,0(s1)
    80005a6c:	c911                	beqz	a0,80005a80 <sys_exec+0xfc>
    kfree(argv[i]);
    80005a6e:	ffffb097          	auipc	ra,0xffffb
    80005a72:	f74080e7          	jalr	-140(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a76:	04a1                	addi	s1,s1,8
    80005a78:	ff3499e3          	bne	s1,s3,80005a6a <sys_exec+0xe6>
    80005a7c:	a011                	j	80005a80 <sys_exec+0xfc>
  return -1;
    80005a7e:	597d                	li	s2,-1
}
    80005a80:	854a                	mv	a0,s2
    80005a82:	60be                	ld	ra,456(sp)
    80005a84:	641e                	ld	s0,448(sp)
    80005a86:	74fa                	ld	s1,440(sp)
    80005a88:	795a                	ld	s2,432(sp)
    80005a8a:	79ba                	ld	s3,424(sp)
    80005a8c:	7a1a                	ld	s4,416(sp)
    80005a8e:	6afa                	ld	s5,408(sp)
    80005a90:	6179                	addi	sp,sp,464
    80005a92:	8082                	ret

0000000080005a94 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a94:	7139                	addi	sp,sp,-64
    80005a96:	fc06                	sd	ra,56(sp)
    80005a98:	f822                	sd	s0,48(sp)
    80005a9a:	f426                	sd	s1,40(sp)
    80005a9c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a9e:	ffffc097          	auipc	ra,0xffffc
    80005aa2:	f6e080e7          	jalr	-146(ra) # 80001a0c <myproc>
    80005aa6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005aa8:	fd840593          	addi	a1,s0,-40
    80005aac:	4501                	li	a0,0
    80005aae:	ffffd097          	auipc	ra,0xffffd
    80005ab2:	066080e7          	jalr	102(ra) # 80002b14 <argaddr>
    return -1;
    80005ab6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ab8:	0e054063          	bltz	a0,80005b98 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005abc:	fc840593          	addi	a1,s0,-56
    80005ac0:	fd040513          	addi	a0,s0,-48
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	de6080e7          	jalr	-538(ra) # 800048aa <pipealloc>
    return -1;
    80005acc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ace:	0c054563          	bltz	a0,80005b98 <sys_pipe+0x104>
  fd0 = -1;
    80005ad2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ad6:	fd043503          	ld	a0,-48(s0)
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	504080e7          	jalr	1284(ra) # 80004fde <fdalloc>
    80005ae2:	fca42223          	sw	a0,-60(s0)
    80005ae6:	08054c63          	bltz	a0,80005b7e <sys_pipe+0xea>
    80005aea:	fc843503          	ld	a0,-56(s0)
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	4f0080e7          	jalr	1264(ra) # 80004fde <fdalloc>
    80005af6:	fca42023          	sw	a0,-64(s0)
    80005afa:	06054963          	bltz	a0,80005b6c <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005afe:	4691                	li	a3,4
    80005b00:	fc440613          	addi	a2,s0,-60
    80005b04:	fd843583          	ld	a1,-40(s0)
    80005b08:	68a8                	ld	a0,80(s1)
    80005b0a:	ffffc097          	auipc	ra,0xffffc
    80005b0e:	b50080e7          	jalr	-1200(ra) # 8000165a <copyout>
    80005b12:	02054063          	bltz	a0,80005b32 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b16:	4691                	li	a3,4
    80005b18:	fc040613          	addi	a2,s0,-64
    80005b1c:	fd843583          	ld	a1,-40(s0)
    80005b20:	0591                	addi	a1,a1,4
    80005b22:	68a8                	ld	a0,80(s1)
    80005b24:	ffffc097          	auipc	ra,0xffffc
    80005b28:	b36080e7          	jalr	-1226(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b2c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b2e:	06055563          	bgez	a0,80005b98 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b32:	fc442783          	lw	a5,-60(s0)
    80005b36:	07e9                	addi	a5,a5,26
    80005b38:	078e                	slli	a5,a5,0x3
    80005b3a:	97a6                	add	a5,a5,s1
    80005b3c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b40:	fc042783          	lw	a5,-64(s0)
    80005b44:	07e9                	addi	a5,a5,26
    80005b46:	078e                	slli	a5,a5,0x3
    80005b48:	00f48533          	add	a0,s1,a5
    80005b4c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b50:	fd043503          	ld	a0,-48(s0)
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	a26080e7          	jalr	-1498(ra) # 8000457a <fileclose>
    fileclose(wf);
    80005b5c:	fc843503          	ld	a0,-56(s0)
    80005b60:	fffff097          	auipc	ra,0xfffff
    80005b64:	a1a080e7          	jalr	-1510(ra) # 8000457a <fileclose>
    return -1;
    80005b68:	57fd                	li	a5,-1
    80005b6a:	a03d                	j	80005b98 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b6c:	fc442783          	lw	a5,-60(s0)
    80005b70:	0007c763          	bltz	a5,80005b7e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b74:	07e9                	addi	a5,a5,26
    80005b76:	078e                	slli	a5,a5,0x3
    80005b78:	97a6                	add	a5,a5,s1
    80005b7a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005b7e:	fd043503          	ld	a0,-48(s0)
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	9f8080e7          	jalr	-1544(ra) # 8000457a <fileclose>
    fileclose(wf);
    80005b8a:	fc843503          	ld	a0,-56(s0)
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	9ec080e7          	jalr	-1556(ra) # 8000457a <fileclose>
    return -1;
    80005b96:	57fd                	li	a5,-1
}
    80005b98:	853e                	mv	a0,a5
    80005b9a:	70e2                	ld	ra,56(sp)
    80005b9c:	7442                	ld	s0,48(sp)
    80005b9e:	74a2                	ld	s1,40(sp)
    80005ba0:	6121                	addi	sp,sp,64
    80005ba2:	8082                	ret
	...

0000000080005bb0 <kernelvec>:
    80005bb0:	7111                	addi	sp,sp,-256
    80005bb2:	e006                	sd	ra,0(sp)
    80005bb4:	e40a                	sd	sp,8(sp)
    80005bb6:	e80e                	sd	gp,16(sp)
    80005bb8:	ec12                	sd	tp,24(sp)
    80005bba:	f016                	sd	t0,32(sp)
    80005bbc:	f41a                	sd	t1,40(sp)
    80005bbe:	f81e                	sd	t2,48(sp)
    80005bc0:	fc22                	sd	s0,56(sp)
    80005bc2:	e0a6                	sd	s1,64(sp)
    80005bc4:	e4aa                	sd	a0,72(sp)
    80005bc6:	e8ae                	sd	a1,80(sp)
    80005bc8:	ecb2                	sd	a2,88(sp)
    80005bca:	f0b6                	sd	a3,96(sp)
    80005bcc:	f4ba                	sd	a4,104(sp)
    80005bce:	f8be                	sd	a5,112(sp)
    80005bd0:	fcc2                	sd	a6,120(sp)
    80005bd2:	e146                	sd	a7,128(sp)
    80005bd4:	e54a                	sd	s2,136(sp)
    80005bd6:	e94e                	sd	s3,144(sp)
    80005bd8:	ed52                	sd	s4,152(sp)
    80005bda:	f156                	sd	s5,160(sp)
    80005bdc:	f55a                	sd	s6,168(sp)
    80005bde:	f95e                	sd	s7,176(sp)
    80005be0:	fd62                	sd	s8,184(sp)
    80005be2:	e1e6                	sd	s9,192(sp)
    80005be4:	e5ea                	sd	s10,200(sp)
    80005be6:	e9ee                	sd	s11,208(sp)
    80005be8:	edf2                	sd	t3,216(sp)
    80005bea:	f1f6                	sd	t4,224(sp)
    80005bec:	f5fa                	sd	t5,232(sp)
    80005bee:	f9fe                	sd	t6,240(sp)
    80005bf0:	d35fc0ef          	jal	ra,80002924 <kerneltrap>
    80005bf4:	6082                	ld	ra,0(sp)
    80005bf6:	6122                	ld	sp,8(sp)
    80005bf8:	61c2                	ld	gp,16(sp)
    80005bfa:	7282                	ld	t0,32(sp)
    80005bfc:	7322                	ld	t1,40(sp)
    80005bfe:	73c2                	ld	t2,48(sp)
    80005c00:	7462                	ld	s0,56(sp)
    80005c02:	6486                	ld	s1,64(sp)
    80005c04:	6526                	ld	a0,72(sp)
    80005c06:	65c6                	ld	a1,80(sp)
    80005c08:	6666                	ld	a2,88(sp)
    80005c0a:	7686                	ld	a3,96(sp)
    80005c0c:	7726                	ld	a4,104(sp)
    80005c0e:	77c6                	ld	a5,112(sp)
    80005c10:	7866                	ld	a6,120(sp)
    80005c12:	688a                	ld	a7,128(sp)
    80005c14:	692a                	ld	s2,136(sp)
    80005c16:	69ca                	ld	s3,144(sp)
    80005c18:	6a6a                	ld	s4,152(sp)
    80005c1a:	7a8a                	ld	s5,160(sp)
    80005c1c:	7b2a                	ld	s6,168(sp)
    80005c1e:	7bca                	ld	s7,176(sp)
    80005c20:	7c6a                	ld	s8,184(sp)
    80005c22:	6c8e                	ld	s9,192(sp)
    80005c24:	6d2e                	ld	s10,200(sp)
    80005c26:	6dce                	ld	s11,208(sp)
    80005c28:	6e6e                	ld	t3,216(sp)
    80005c2a:	7e8e                	ld	t4,224(sp)
    80005c2c:	7f2e                	ld	t5,232(sp)
    80005c2e:	7fce                	ld	t6,240(sp)
    80005c30:	6111                	addi	sp,sp,256
    80005c32:	10200073          	sret
    80005c36:	00000013          	nop
    80005c3a:	00000013          	nop
    80005c3e:	0001                	nop

0000000080005c40 <timervec>:
    80005c40:	34051573          	csrrw	a0,mscratch,a0
    80005c44:	e10c                	sd	a1,0(a0)
    80005c46:	e510                	sd	a2,8(a0)
    80005c48:	e914                	sd	a3,16(a0)
    80005c4a:	6d0c                	ld	a1,24(a0)
    80005c4c:	7110                	ld	a2,32(a0)
    80005c4e:	6194                	ld	a3,0(a1)
    80005c50:	96b2                	add	a3,a3,a2
    80005c52:	e194                	sd	a3,0(a1)
    80005c54:	4589                	li	a1,2
    80005c56:	14459073          	csrw	sip,a1
    80005c5a:	6914                	ld	a3,16(a0)
    80005c5c:	6510                	ld	a2,8(a0)
    80005c5e:	610c                	ld	a1,0(a0)
    80005c60:	34051573          	csrrw	a0,mscratch,a0
    80005c64:	30200073          	mret
	...

0000000080005c6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c6a:	1141                	addi	sp,sp,-16
    80005c6c:	e422                	sd	s0,8(sp)
    80005c6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c70:	0c0007b7          	lui	a5,0xc000
    80005c74:	4705                	li	a4,1
    80005c76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c78:	c3d8                	sw	a4,4(a5)
}
    80005c7a:	6422                	ld	s0,8(sp)
    80005c7c:	0141                	addi	sp,sp,16
    80005c7e:	8082                	ret

0000000080005c80 <plicinithart>:

void
plicinithart(void)
{
    80005c80:	1141                	addi	sp,sp,-16
    80005c82:	e406                	sd	ra,8(sp)
    80005c84:	e022                	sd	s0,0(sp)
    80005c86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	d58080e7          	jalr	-680(ra) # 800019e0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c90:	0085171b          	slliw	a4,a0,0x8
    80005c94:	0c0027b7          	lui	a5,0xc002
    80005c98:	97ba                	add	a5,a5,a4
    80005c9a:	40200713          	li	a4,1026
    80005c9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ca2:	00d5151b          	slliw	a0,a0,0xd
    80005ca6:	0c2017b7          	lui	a5,0xc201
    80005caa:	97aa                	add	a5,a5,a0
    80005cac:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005cb0:	60a2                	ld	ra,8(sp)
    80005cb2:	6402                	ld	s0,0(sp)
    80005cb4:	0141                	addi	sp,sp,16
    80005cb6:	8082                	ret

0000000080005cb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cb8:	1141                	addi	sp,sp,-16
    80005cba:	e406                	sd	ra,8(sp)
    80005cbc:	e022                	sd	s0,0(sp)
    80005cbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cc0:	ffffc097          	auipc	ra,0xffffc
    80005cc4:	d20080e7          	jalr	-736(ra) # 800019e0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cc8:	00d5151b          	slliw	a0,a0,0xd
    80005ccc:	0c2017b7          	lui	a5,0xc201
    80005cd0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005cd2:	43c8                	lw	a0,4(a5)
    80005cd4:	60a2                	ld	ra,8(sp)
    80005cd6:	6402                	ld	s0,0(sp)
    80005cd8:	0141                	addi	sp,sp,16
    80005cda:	8082                	ret

0000000080005cdc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cdc:	1101                	addi	sp,sp,-32
    80005cde:	ec06                	sd	ra,24(sp)
    80005ce0:	e822                	sd	s0,16(sp)
    80005ce2:	e426                	sd	s1,8(sp)
    80005ce4:	1000                	addi	s0,sp,32
    80005ce6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	cf8080e7          	jalr	-776(ra) # 800019e0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cf0:	00d5151b          	slliw	a0,a0,0xd
    80005cf4:	0c2017b7          	lui	a5,0xc201
    80005cf8:	97aa                	add	a5,a5,a0
    80005cfa:	c3c4                	sw	s1,4(a5)
}
    80005cfc:	60e2                	ld	ra,24(sp)
    80005cfe:	6442                	ld	s0,16(sp)
    80005d00:	64a2                	ld	s1,8(sp)
    80005d02:	6105                	addi	sp,sp,32
    80005d04:	8082                	ret

0000000080005d06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d06:	1141                	addi	sp,sp,-16
    80005d08:	e406                	sd	ra,8(sp)
    80005d0a:	e022                	sd	s0,0(sp)
    80005d0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d0e:	479d                	li	a5,7
    80005d10:	06a7c863          	blt	a5,a0,80005d80 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005d14:	0001d717          	auipc	a4,0x1d
    80005d18:	2ec70713          	addi	a4,a4,748 # 80023000 <disk>
    80005d1c:	972a                	add	a4,a4,a0
    80005d1e:	6789                	lui	a5,0x2
    80005d20:	97ba                	add	a5,a5,a4
    80005d22:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d26:	e7ad                	bnez	a5,80005d90 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d28:	00451793          	slli	a5,a0,0x4
    80005d2c:	0001f717          	auipc	a4,0x1f
    80005d30:	2d470713          	addi	a4,a4,724 # 80025000 <disk+0x2000>
    80005d34:	6314                	ld	a3,0(a4)
    80005d36:	96be                	add	a3,a3,a5
    80005d38:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d3c:	6314                	ld	a3,0(a4)
    80005d3e:	96be                	add	a3,a3,a5
    80005d40:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d44:	6314                	ld	a3,0(a4)
    80005d46:	96be                	add	a3,a3,a5
    80005d48:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d4c:	6318                	ld	a4,0(a4)
    80005d4e:	97ba                	add	a5,a5,a4
    80005d50:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d54:	0001d717          	auipc	a4,0x1d
    80005d58:	2ac70713          	addi	a4,a4,684 # 80023000 <disk>
    80005d5c:	972a                	add	a4,a4,a0
    80005d5e:	6789                	lui	a5,0x2
    80005d60:	97ba                	add	a5,a5,a4
    80005d62:	4705                	li	a4,1
    80005d64:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d68:	0001f517          	auipc	a0,0x1f
    80005d6c:	2b050513          	addi	a0,a0,688 # 80025018 <disk+0x2018>
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	51c080e7          	jalr	1308(ra) # 8000228c <wakeup>
}
    80005d78:	60a2                	ld	ra,8(sp)
    80005d7a:	6402                	ld	s0,0(sp)
    80005d7c:	0141                	addi	sp,sp,16
    80005d7e:	8082                	ret
    panic("free_desc 1");
    80005d80:	00003517          	auipc	a0,0x3
    80005d84:	a8850513          	addi	a0,a0,-1400 # 80008808 <syscalls+0x340>
    80005d88:	ffffa097          	auipc	ra,0xffffa
    80005d8c:	7b2080e7          	jalr	1970(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005d90:	00003517          	auipc	a0,0x3
    80005d94:	a8850513          	addi	a0,a0,-1400 # 80008818 <syscalls+0x350>
    80005d98:	ffffa097          	auipc	ra,0xffffa
    80005d9c:	7a2080e7          	jalr	1954(ra) # 8000053a <panic>

0000000080005da0 <virtio_disk_init>:
{
    80005da0:	1101                	addi	sp,sp,-32
    80005da2:	ec06                	sd	ra,24(sp)
    80005da4:	e822                	sd	s0,16(sp)
    80005da6:	e426                	sd	s1,8(sp)
    80005da8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005daa:	00003597          	auipc	a1,0x3
    80005dae:	a7e58593          	addi	a1,a1,-1410 # 80008828 <syscalls+0x360>
    80005db2:	0001f517          	auipc	a0,0x1f
    80005db6:	37650513          	addi	a0,a0,886 # 80025128 <disk+0x2128>
    80005dba:	ffffb097          	auipc	ra,0xffffb
    80005dbe:	d86080e7          	jalr	-634(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dc2:	100017b7          	lui	a5,0x10001
    80005dc6:	4398                	lw	a4,0(a5)
    80005dc8:	2701                	sext.w	a4,a4
    80005dca:	747277b7          	lui	a5,0x74727
    80005dce:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dd2:	0ef71063          	bne	a4,a5,80005eb2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dd6:	100017b7          	lui	a5,0x10001
    80005dda:	43dc                	lw	a5,4(a5)
    80005ddc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dde:	4705                	li	a4,1
    80005de0:	0ce79963          	bne	a5,a4,80005eb2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005de4:	100017b7          	lui	a5,0x10001
    80005de8:	479c                	lw	a5,8(a5)
    80005dea:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dec:	4709                	li	a4,2
    80005dee:	0ce79263          	bne	a5,a4,80005eb2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005df2:	100017b7          	lui	a5,0x10001
    80005df6:	47d8                	lw	a4,12(a5)
    80005df8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dfa:	554d47b7          	lui	a5,0x554d4
    80005dfe:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e02:	0af71863          	bne	a4,a5,80005eb2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e06:	100017b7          	lui	a5,0x10001
    80005e0a:	4705                	li	a4,1
    80005e0c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e0e:	470d                	li	a4,3
    80005e10:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e12:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e14:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e18:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e1c:	8f75                	and	a4,a4,a3
    80005e1e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e20:	472d                	li	a4,11
    80005e22:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e24:	473d                	li	a4,15
    80005e26:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e28:	6705                	lui	a4,0x1
    80005e2a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e2c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e30:	5bdc                	lw	a5,52(a5)
    80005e32:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e34:	c7d9                	beqz	a5,80005ec2 <virtio_disk_init+0x122>
  if(max < NUM)
    80005e36:	471d                	li	a4,7
    80005e38:	08f77d63          	bgeu	a4,a5,80005ed2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e3c:	100014b7          	lui	s1,0x10001
    80005e40:	47a1                	li	a5,8
    80005e42:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e44:	6609                	lui	a2,0x2
    80005e46:	4581                	li	a1,0
    80005e48:	0001d517          	auipc	a0,0x1d
    80005e4c:	1b850513          	addi	a0,a0,440 # 80023000 <disk>
    80005e50:	ffffb097          	auipc	ra,0xffffb
    80005e54:	e7c080e7          	jalr	-388(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e58:	0001d717          	auipc	a4,0x1d
    80005e5c:	1a870713          	addi	a4,a4,424 # 80023000 <disk>
    80005e60:	00c75793          	srli	a5,a4,0xc
    80005e64:	2781                	sext.w	a5,a5
    80005e66:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e68:	0001f797          	auipc	a5,0x1f
    80005e6c:	19878793          	addi	a5,a5,408 # 80025000 <disk+0x2000>
    80005e70:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e72:	0001d717          	auipc	a4,0x1d
    80005e76:	20e70713          	addi	a4,a4,526 # 80023080 <disk+0x80>
    80005e7a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e7c:	0001e717          	auipc	a4,0x1e
    80005e80:	18470713          	addi	a4,a4,388 # 80024000 <disk+0x1000>
    80005e84:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e86:	4705                	li	a4,1
    80005e88:	00e78c23          	sb	a4,24(a5)
    80005e8c:	00e78ca3          	sb	a4,25(a5)
    80005e90:	00e78d23          	sb	a4,26(a5)
    80005e94:	00e78da3          	sb	a4,27(a5)
    80005e98:	00e78e23          	sb	a4,28(a5)
    80005e9c:	00e78ea3          	sb	a4,29(a5)
    80005ea0:	00e78f23          	sb	a4,30(a5)
    80005ea4:	00e78fa3          	sb	a4,31(a5)
}
    80005ea8:	60e2                	ld	ra,24(sp)
    80005eaa:	6442                	ld	s0,16(sp)
    80005eac:	64a2                	ld	s1,8(sp)
    80005eae:	6105                	addi	sp,sp,32
    80005eb0:	8082                	ret
    panic("could not find virtio disk");
    80005eb2:	00003517          	auipc	a0,0x3
    80005eb6:	98650513          	addi	a0,a0,-1658 # 80008838 <syscalls+0x370>
    80005eba:	ffffa097          	auipc	ra,0xffffa
    80005ebe:	680080e7          	jalr	1664(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005ec2:	00003517          	auipc	a0,0x3
    80005ec6:	99650513          	addi	a0,a0,-1642 # 80008858 <syscalls+0x390>
    80005eca:	ffffa097          	auipc	ra,0xffffa
    80005ece:	670080e7          	jalr	1648(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	9a650513          	addi	a0,a0,-1626 # 80008878 <syscalls+0x3b0>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	660080e7          	jalr	1632(ra) # 8000053a <panic>

0000000080005ee2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ee2:	7119                	addi	sp,sp,-128
    80005ee4:	fc86                	sd	ra,120(sp)
    80005ee6:	f8a2                	sd	s0,112(sp)
    80005ee8:	f4a6                	sd	s1,104(sp)
    80005eea:	f0ca                	sd	s2,96(sp)
    80005eec:	ecce                	sd	s3,88(sp)
    80005eee:	e8d2                	sd	s4,80(sp)
    80005ef0:	e4d6                	sd	s5,72(sp)
    80005ef2:	e0da                	sd	s6,64(sp)
    80005ef4:	fc5e                	sd	s7,56(sp)
    80005ef6:	f862                	sd	s8,48(sp)
    80005ef8:	f466                	sd	s9,40(sp)
    80005efa:	f06a                	sd	s10,32(sp)
    80005efc:	ec6e                	sd	s11,24(sp)
    80005efe:	0100                	addi	s0,sp,128
    80005f00:	8aaa                	mv	s5,a0
    80005f02:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f04:	00c52c83          	lw	s9,12(a0)
    80005f08:	001c9c9b          	slliw	s9,s9,0x1
    80005f0c:	1c82                	slli	s9,s9,0x20
    80005f0e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f12:	0001f517          	auipc	a0,0x1f
    80005f16:	21650513          	addi	a0,a0,534 # 80025128 <disk+0x2128>
    80005f1a:	ffffb097          	auipc	ra,0xffffb
    80005f1e:	cb6080e7          	jalr	-842(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005f22:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f24:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f26:	0001dc17          	auipc	s8,0x1d
    80005f2a:	0dac0c13          	addi	s8,s8,218 # 80023000 <disk>
    80005f2e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f30:	4b0d                	li	s6,3
    80005f32:	a0ad                	j	80005f9c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f34:	00fc0733          	add	a4,s8,a5
    80005f38:	975e                	add	a4,a4,s7
    80005f3a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f3e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f40:	0207c563          	bltz	a5,80005f6a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f44:	2905                	addiw	s2,s2,1
    80005f46:	0611                	addi	a2,a2,4
    80005f48:	19690c63          	beq	s2,s6,800060e0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005f4c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f4e:	0001f717          	auipc	a4,0x1f
    80005f52:	0ca70713          	addi	a4,a4,202 # 80025018 <disk+0x2018>
    80005f56:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f58:	00074683          	lbu	a3,0(a4)
    80005f5c:	fee1                	bnez	a3,80005f34 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f5e:	2785                	addiw	a5,a5,1
    80005f60:	0705                	addi	a4,a4,1
    80005f62:	fe979be3          	bne	a5,s1,80005f58 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f66:	57fd                	li	a5,-1
    80005f68:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f6a:	01205d63          	blez	s2,80005f84 <virtio_disk_rw+0xa2>
    80005f6e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f70:	000a2503          	lw	a0,0(s4)
    80005f74:	00000097          	auipc	ra,0x0
    80005f78:	d92080e7          	jalr	-622(ra) # 80005d06 <free_desc>
      for(int j = 0; j < i; j++)
    80005f7c:	2d85                	addiw	s11,s11,1
    80005f7e:	0a11                	addi	s4,s4,4
    80005f80:	ff2d98e3          	bne	s11,s2,80005f70 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f84:	0001f597          	auipc	a1,0x1f
    80005f88:	1a458593          	addi	a1,a1,420 # 80025128 <disk+0x2128>
    80005f8c:	0001f517          	auipc	a0,0x1f
    80005f90:	08c50513          	addi	a0,a0,140 # 80025018 <disk+0x2018>
    80005f94:	ffffc097          	auipc	ra,0xffffc
    80005f98:	16c080e7          	jalr	364(ra) # 80002100 <sleep>
  for(int i = 0; i < 3; i++){
    80005f9c:	f8040a13          	addi	s4,s0,-128
{
    80005fa0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fa2:	894e                	mv	s2,s3
    80005fa4:	b765                	j	80005f4c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fa6:	0001f697          	auipc	a3,0x1f
    80005faa:	05a6b683          	ld	a3,90(a3) # 80025000 <disk+0x2000>
    80005fae:	96ba                	add	a3,a3,a4
    80005fb0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fb4:	0001d817          	auipc	a6,0x1d
    80005fb8:	04c80813          	addi	a6,a6,76 # 80023000 <disk>
    80005fbc:	0001f697          	auipc	a3,0x1f
    80005fc0:	04468693          	addi	a3,a3,68 # 80025000 <disk+0x2000>
    80005fc4:	6290                	ld	a2,0(a3)
    80005fc6:	963a                	add	a2,a2,a4
    80005fc8:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80005fcc:	0015e593          	ori	a1,a1,1
    80005fd0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005fd4:	f8842603          	lw	a2,-120(s0)
    80005fd8:	628c                	ld	a1,0(a3)
    80005fda:	972e                	add	a4,a4,a1
    80005fdc:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fe0:	20050593          	addi	a1,a0,512
    80005fe4:	0592                	slli	a1,a1,0x4
    80005fe6:	95c2                	add	a1,a1,a6
    80005fe8:	577d                	li	a4,-1
    80005fea:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fee:	00461713          	slli	a4,a2,0x4
    80005ff2:	6290                	ld	a2,0(a3)
    80005ff4:	963a                	add	a2,a2,a4
    80005ff6:	03078793          	addi	a5,a5,48
    80005ffa:	97c2                	add	a5,a5,a6
    80005ffc:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005ffe:	629c                	ld	a5,0(a3)
    80006000:	97ba                	add	a5,a5,a4
    80006002:	4605                	li	a2,1
    80006004:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006006:	629c                	ld	a5,0(a3)
    80006008:	97ba                	add	a5,a5,a4
    8000600a:	4809                	li	a6,2
    8000600c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006010:	629c                	ld	a5,0(a3)
    80006012:	97ba                	add	a5,a5,a4
    80006014:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006018:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000601c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006020:	6698                	ld	a4,8(a3)
    80006022:	00275783          	lhu	a5,2(a4)
    80006026:	8b9d                	andi	a5,a5,7
    80006028:	0786                	slli	a5,a5,0x1
    8000602a:	973e                	add	a4,a4,a5
    8000602c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006030:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006034:	6698                	ld	a4,8(a3)
    80006036:	00275783          	lhu	a5,2(a4)
    8000603a:	2785                	addiw	a5,a5,1
    8000603c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006040:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006044:	100017b7          	lui	a5,0x10001
    80006048:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000604c:	004aa783          	lw	a5,4(s5)
    80006050:	02c79163          	bne	a5,a2,80006072 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006054:	0001f917          	auipc	s2,0x1f
    80006058:	0d490913          	addi	s2,s2,212 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000605c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000605e:	85ca                	mv	a1,s2
    80006060:	8556                	mv	a0,s5
    80006062:	ffffc097          	auipc	ra,0xffffc
    80006066:	09e080e7          	jalr	158(ra) # 80002100 <sleep>
  while(b->disk == 1) {
    8000606a:	004aa783          	lw	a5,4(s5)
    8000606e:	fe9788e3          	beq	a5,s1,8000605e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006072:	f8042903          	lw	s2,-128(s0)
    80006076:	20090713          	addi	a4,s2,512
    8000607a:	0712                	slli	a4,a4,0x4
    8000607c:	0001d797          	auipc	a5,0x1d
    80006080:	f8478793          	addi	a5,a5,-124 # 80023000 <disk>
    80006084:	97ba                	add	a5,a5,a4
    80006086:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000608a:	0001f997          	auipc	s3,0x1f
    8000608e:	f7698993          	addi	s3,s3,-138 # 80025000 <disk+0x2000>
    80006092:	00491713          	slli	a4,s2,0x4
    80006096:	0009b783          	ld	a5,0(s3)
    8000609a:	97ba                	add	a5,a5,a4
    8000609c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060a0:	854a                	mv	a0,s2
    800060a2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060a6:	00000097          	auipc	ra,0x0
    800060aa:	c60080e7          	jalr	-928(ra) # 80005d06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060ae:	8885                	andi	s1,s1,1
    800060b0:	f0ed                	bnez	s1,80006092 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060b2:	0001f517          	auipc	a0,0x1f
    800060b6:	07650513          	addi	a0,a0,118 # 80025128 <disk+0x2128>
    800060ba:	ffffb097          	auipc	ra,0xffffb
    800060be:	bca080e7          	jalr	-1078(ra) # 80000c84 <release>
}
    800060c2:	70e6                	ld	ra,120(sp)
    800060c4:	7446                	ld	s0,112(sp)
    800060c6:	74a6                	ld	s1,104(sp)
    800060c8:	7906                	ld	s2,96(sp)
    800060ca:	69e6                	ld	s3,88(sp)
    800060cc:	6a46                	ld	s4,80(sp)
    800060ce:	6aa6                	ld	s5,72(sp)
    800060d0:	6b06                	ld	s6,64(sp)
    800060d2:	7be2                	ld	s7,56(sp)
    800060d4:	7c42                	ld	s8,48(sp)
    800060d6:	7ca2                	ld	s9,40(sp)
    800060d8:	7d02                	ld	s10,32(sp)
    800060da:	6de2                	ld	s11,24(sp)
    800060dc:	6109                	addi	sp,sp,128
    800060de:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060e0:	f8042503          	lw	a0,-128(s0)
    800060e4:	20050793          	addi	a5,a0,512
    800060e8:	0792                	slli	a5,a5,0x4
  if(write)
    800060ea:	0001d817          	auipc	a6,0x1d
    800060ee:	f1680813          	addi	a6,a6,-234 # 80023000 <disk>
    800060f2:	00f80733          	add	a4,a6,a5
    800060f6:	01a036b3          	snez	a3,s10
    800060fa:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800060fe:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006102:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006106:	7679                	lui	a2,0xffffe
    80006108:	963e                	add	a2,a2,a5
    8000610a:	0001f697          	auipc	a3,0x1f
    8000610e:	ef668693          	addi	a3,a3,-266 # 80025000 <disk+0x2000>
    80006112:	6298                	ld	a4,0(a3)
    80006114:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006116:	0a878593          	addi	a1,a5,168
    8000611a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000611c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000611e:	6298                	ld	a4,0(a3)
    80006120:	9732                	add	a4,a4,a2
    80006122:	45c1                	li	a1,16
    80006124:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006126:	6298                	ld	a4,0(a3)
    80006128:	9732                	add	a4,a4,a2
    8000612a:	4585                	li	a1,1
    8000612c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006130:	f8442703          	lw	a4,-124(s0)
    80006134:	628c                	ld	a1,0(a3)
    80006136:	962e                	add	a2,a2,a1
    80006138:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000613c:	0712                	slli	a4,a4,0x4
    8000613e:	6290                	ld	a2,0(a3)
    80006140:	963a                	add	a2,a2,a4
    80006142:	058a8593          	addi	a1,s5,88
    80006146:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006148:	6294                	ld	a3,0(a3)
    8000614a:	96ba                	add	a3,a3,a4
    8000614c:	40000613          	li	a2,1024
    80006150:	c690                	sw	a2,8(a3)
  if(write)
    80006152:	e40d1ae3          	bnez	s10,80005fa6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006156:	0001f697          	auipc	a3,0x1f
    8000615a:	eaa6b683          	ld	a3,-342(a3) # 80025000 <disk+0x2000>
    8000615e:	96ba                	add	a3,a3,a4
    80006160:	4609                	li	a2,2
    80006162:	00c69623          	sh	a2,12(a3)
    80006166:	b5b9                	j	80005fb4 <virtio_disk_rw+0xd2>

0000000080006168 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006168:	1101                	addi	sp,sp,-32
    8000616a:	ec06                	sd	ra,24(sp)
    8000616c:	e822                	sd	s0,16(sp)
    8000616e:	e426                	sd	s1,8(sp)
    80006170:	e04a                	sd	s2,0(sp)
    80006172:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006174:	0001f517          	auipc	a0,0x1f
    80006178:	fb450513          	addi	a0,a0,-76 # 80025128 <disk+0x2128>
    8000617c:	ffffb097          	auipc	ra,0xffffb
    80006180:	a54080e7          	jalr	-1452(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006184:	10001737          	lui	a4,0x10001
    80006188:	533c                	lw	a5,96(a4)
    8000618a:	8b8d                	andi	a5,a5,3
    8000618c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000618e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006192:	0001f797          	auipc	a5,0x1f
    80006196:	e6e78793          	addi	a5,a5,-402 # 80025000 <disk+0x2000>
    8000619a:	6b94                	ld	a3,16(a5)
    8000619c:	0207d703          	lhu	a4,32(a5)
    800061a0:	0026d783          	lhu	a5,2(a3)
    800061a4:	06f70163          	beq	a4,a5,80006206 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061a8:	0001d917          	auipc	s2,0x1d
    800061ac:	e5890913          	addi	s2,s2,-424 # 80023000 <disk>
    800061b0:	0001f497          	auipc	s1,0x1f
    800061b4:	e5048493          	addi	s1,s1,-432 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800061b8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061bc:	6898                	ld	a4,16(s1)
    800061be:	0204d783          	lhu	a5,32(s1)
    800061c2:	8b9d                	andi	a5,a5,7
    800061c4:	078e                	slli	a5,a5,0x3
    800061c6:	97ba                	add	a5,a5,a4
    800061c8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061ca:	20078713          	addi	a4,a5,512
    800061ce:	0712                	slli	a4,a4,0x4
    800061d0:	974a                	add	a4,a4,s2
    800061d2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800061d6:	e731                	bnez	a4,80006222 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061d8:	20078793          	addi	a5,a5,512
    800061dc:	0792                	slli	a5,a5,0x4
    800061de:	97ca                	add	a5,a5,s2
    800061e0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800061e2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061e6:	ffffc097          	auipc	ra,0xffffc
    800061ea:	0a6080e7          	jalr	166(ra) # 8000228c <wakeup>

    disk.used_idx += 1;
    800061ee:	0204d783          	lhu	a5,32(s1)
    800061f2:	2785                	addiw	a5,a5,1
    800061f4:	17c2                	slli	a5,a5,0x30
    800061f6:	93c1                	srli	a5,a5,0x30
    800061f8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061fc:	6898                	ld	a4,16(s1)
    800061fe:	00275703          	lhu	a4,2(a4)
    80006202:	faf71be3          	bne	a4,a5,800061b8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006206:	0001f517          	auipc	a0,0x1f
    8000620a:	f2250513          	addi	a0,a0,-222 # 80025128 <disk+0x2128>
    8000620e:	ffffb097          	auipc	ra,0xffffb
    80006212:	a76080e7          	jalr	-1418(ra) # 80000c84 <release>
}
    80006216:	60e2                	ld	ra,24(sp)
    80006218:	6442                	ld	s0,16(sp)
    8000621a:	64a2                	ld	s1,8(sp)
    8000621c:	6902                	ld	s2,0(sp)
    8000621e:	6105                	addi	sp,sp,32
    80006220:	8082                	ret
      panic("virtio_disk_intr status");
    80006222:	00002517          	auipc	a0,0x2
    80006226:	67650513          	addi	a0,a0,1654 # 80008898 <syscalls+0x3d0>
    8000622a:	ffffa097          	auipc	ra,0xffffa
    8000622e:	310080e7          	jalr	784(ra) # 8000053a <panic>
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
