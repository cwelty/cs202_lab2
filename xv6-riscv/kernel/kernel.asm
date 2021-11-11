
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	90013103          	ld	sp,-1792(sp) # 80008900 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	bcc78793          	addi	a5,a5,-1076 # 80005c30 <timervec>
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
    80000130:	3e0080e7          	jalr	992(ra) # 8000250c <either_copyin>
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
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
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
    800001c8:	862080e7          	jalr	-1950(ra) # 80001a26 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f3e080e7          	jalr	-194(ra) # 80002112 <sleep>
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
    80000214:	2a6080e7          	jalr	678(ra) # 800024b6 <either_copyout>
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
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
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
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
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
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
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
    800002f6:	270080e7          	jalr	624(ra) # 80002562 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
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
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
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
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
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
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
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
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
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
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e58080e7          	jalr	-424(ra) # 8000229e <wakeup>
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
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	0a078793          	addi	a5,a5,160 # 80021518 <devsw>
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
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
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
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
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
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
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
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
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
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
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
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
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
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
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
    800008a4:	9fe080e7          	jalr	-1538(ra) # 8000229e <wakeup>
    
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
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
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
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	7e6080e7          	jalr	2022(ra) # 80002112 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
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
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
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
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
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
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
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
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
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
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
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
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
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
    80000b82:	e8c080e7          	jalr	-372(ra) # 80001a0a <mycpu>
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
    80000bb4:	e5a080e7          	jalr	-422(ra) # 80001a0a <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e4e080e7          	jalr	-434(ra) # 80001a0a <mycpu>
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
    80000bd8:	e36080e7          	jalr	-458(ra) # 80001a0a <mycpu>
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
    80000c18:	df6080e7          	jalr	-522(ra) # 80001a0a <mycpu>
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
    80000c44:	dca080e7          	jalr	-566(ra) # 80001a0a <mycpu>
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
    80000e9a:	b64080e7          	jalr	-1180(ra) # 800019fa <cpuid>
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
    80000eb6:	b48080e7          	jalr	-1208(ra) # 800019fa <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	7ce080e7          	jalr	1998(ra) # 800026a2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	d94080e7          	jalr	-620(ra) # 80005c70 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	07c080e7          	jalr	124(ra) # 80001f60 <scheduler>
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
    80000f48:	a06080e7          	jalr	-1530(ra) # 8000194a <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	72e080e7          	jalr	1838(ra) # 8000267a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	74e080e7          	jalr	1870(ra) # 800026a2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	cfe080e7          	jalr	-770(ra) # 80005c5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	d0c080e7          	jalr	-756(ra) # 80005c70 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	eea080e7          	jalr	-278(ra) # 80002e56 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	57a080e7          	jalr	1402(ra) # 800034ee <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	524080e7          	jalr	1316(ra) # 800044a0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	e0e080e7          	jalr	-498(ra) # 80005d92 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	da2080e7          	jalr	-606(ra) # 80001d2e <userinit>
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
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
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

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	a62a0a13          	addi	s4,s4,-1438 # 800172d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	17048493          	addi	s1,s1,368
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <process_count_print>:
	struct proc *p = myproc();
	int syscallCount = p->syscallCount;
	printf("Number of system calls made by the current process: %d\n", syscallCount);
}

void process_count_print(void){
    800018d4:	1141                	addi	sp,sp,-16
    800018d6:	e406                	sd	ra,8(sp)
    800018d8:	e022                	sd	s0,0(sp)
    800018da:	0800                	addi	s0,sp,16
  struct proc *p;
  int count = 0;
    800018dc:	4581                	li	a1,0
  for(p = proc; p < &proc[NPROC]; p++){
    800018de:	00010797          	auipc	a5,0x10
    800018e2:	df278793          	addi	a5,a5,-526 # 800116d0 <proc>
    800018e6:	00016697          	auipc	a3,0x16
    800018ea:	9ea68693          	addi	a3,a3,-1558 # 800172d0 <tickslock>
    800018ee:	a029                	j	800018f8 <process_count_print+0x24>
    800018f0:	17078793          	addi	a5,a5,368
    800018f4:	00d78663          	beq	a5,a3,80001900 <process_count_print+0x2c>
    if(p->state == UNUSED)
    800018f8:	4f98                	lw	a4,24(a5)
    800018fa:	db7d                	beqz	a4,800018f0 <process_count_print+0x1c>
      continue;
    count++;
    800018fc:	2585                	addiw	a1,a1,1
    800018fe:	bfcd                	j	800018f0 <process_count_print+0x1c>
  }

  printf("Number of processes in the system: %d\n", count); 
    80001900:	00007517          	auipc	a0,0x7
    80001904:	8e050513          	addi	a0,a0,-1824 # 800081e0 <digits+0x1a0>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	c80080e7          	jalr	-896(ra) # 80000588 <printf>

}
    80001910:	60a2                	ld	ra,8(sp)
    80001912:	6402                	ld	s0,0(sp)
    80001914:	0141                	addi	sp,sp,16
    80001916:	8082                	ret

0000000080001918 <mem_pages_count_print>:

void mem_pages_count_print(void){
    80001918:	1141                	addi	sp,sp,-16
    8000191a:	e406                	sd	ra,8(sp)
    8000191c:	e022                	sd	s0,0(sp)
    8000191e:	0800                	addi	s0,sp,16
  uint memPagesCount = (PGROUNDUP(proc->sz)) / PGSIZE;
    80001920:	00010597          	auipc	a1,0x10
    80001924:	df85b583          	ld	a1,-520(a1) # 80011718 <proc+0x48>
    80001928:	6785                	lui	a5,0x1
    8000192a:	17fd                	addi	a5,a5,-1
    8000192c:	95be                	add	a1,a1,a5
    8000192e:	81b1                	srli	a1,a1,0xc
  printf("Number of memory pages: %d\n", memPagesCount);
    80001930:	2581                	sext.w	a1,a1
    80001932:	00007517          	auipc	a0,0x7
    80001936:	8d650513          	addi	a0,a0,-1834 # 80008208 <digits+0x1c8>
    8000193a:	fffff097          	auipc	ra,0xfffff
    8000193e:	c4e080e7          	jalr	-946(ra) # 80000588 <printf>
}
    80001942:	60a2                	ld	ra,8(sp)
    80001944:	6402                	ld	s0,0(sp)
    80001946:	0141                	addi	sp,sp,16
    80001948:	8082                	ret

000000008000194a <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    8000194a:	7139                	addi	sp,sp,-64
    8000194c:	fc06                	sd	ra,56(sp)
    8000194e:	f822                	sd	s0,48(sp)
    80001950:	f426                	sd	s1,40(sp)
    80001952:	f04a                	sd	s2,32(sp)
    80001954:	ec4e                	sd	s3,24(sp)
    80001956:	e852                	sd	s4,16(sp)
    80001958:	e456                	sd	s5,8(sp)
    8000195a:	e05a                	sd	s6,0(sp)
    8000195c:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000195e:	00007597          	auipc	a1,0x7
    80001962:	8ca58593          	addi	a1,a1,-1846 # 80008228 <digits+0x1e8>
    80001966:	00010517          	auipc	a0,0x10
    8000196a:	93a50513          	addi	a0,a0,-1734 # 800112a0 <pid_lock>
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	1e6080e7          	jalr	486(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001976:	00007597          	auipc	a1,0x7
    8000197a:	8ba58593          	addi	a1,a1,-1862 # 80008230 <digits+0x1f0>
    8000197e:	00010517          	auipc	a0,0x10
    80001982:	93a50513          	addi	a0,a0,-1734 # 800112b8 <wait_lock>
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	1ce080e7          	jalr	462(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198e:	00010497          	auipc	s1,0x10
    80001992:	d4248493          	addi	s1,s1,-702 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001996:	00007b17          	auipc	s6,0x7
    8000199a:	8aab0b13          	addi	s6,s6,-1878 # 80008240 <digits+0x200>
      p->kstack = KSTACK((int) (p - proc));
    8000199e:	8aa6                	mv	s5,s1
    800019a0:	00006a17          	auipc	s4,0x6
    800019a4:	660a0a13          	addi	s4,s4,1632 # 80008000 <etext>
    800019a8:	04000937          	lui	s2,0x4000
    800019ac:	197d                	addi	s2,s2,-1
    800019ae:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b0:	00016997          	auipc	s3,0x16
    800019b4:	92098993          	addi	s3,s3,-1760 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    800019b8:	85da                	mv	a1,s6
    800019ba:	8526                	mv	a0,s1
    800019bc:	fffff097          	auipc	ra,0xfffff
    800019c0:	198080e7          	jalr	408(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019c4:	415487b3          	sub	a5,s1,s5
    800019c8:	8791                	srai	a5,a5,0x4
    800019ca:	000a3703          	ld	a4,0(s4)
    800019ce:	02e787b3          	mul	a5,a5,a4
    800019d2:	2785                	addiw	a5,a5,1
    800019d4:	00d7979b          	slliw	a5,a5,0xd
    800019d8:	40f907b3          	sub	a5,s2,a5
    800019dc:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019de:	17048493          	addi	s1,s1,368
    800019e2:	fd349be3          	bne	s1,s3,800019b8 <procinit+0x6e>
  }
}
    800019e6:	70e2                	ld	ra,56(sp)
    800019e8:	7442                	ld	s0,48(sp)
    800019ea:	74a2                	ld	s1,40(sp)
    800019ec:	7902                	ld	s2,32(sp)
    800019ee:	69e2                	ld	s3,24(sp)
    800019f0:	6a42                	ld	s4,16(sp)
    800019f2:	6aa2                	ld	s5,8(sp)
    800019f4:	6b02                	ld	s6,0(sp)
    800019f6:	6121                	addi	sp,sp,64
    800019f8:	8082                	ret

00000000800019fa <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019fa:	1141                	addi	sp,sp,-16
    800019fc:	e422                	sd	s0,8(sp)
    800019fe:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a00:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a02:	2501                	sext.w	a0,a0
    80001a04:	6422                	ld	s0,8(sp)
    80001a06:	0141                	addi	sp,sp,16
    80001a08:	8082                	ret

0000000080001a0a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a0a:	1141                	addi	sp,sp,-16
    80001a0c:	e422                	sd	s0,8(sp)
    80001a0e:	0800                	addi	s0,sp,16
    80001a10:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a12:	2781                	sext.w	a5,a5
    80001a14:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a16:	00010517          	auipc	a0,0x10
    80001a1a:	8ba50513          	addi	a0,a0,-1862 # 800112d0 <cpus>
    80001a1e:	953e                	add	a0,a0,a5
    80001a20:	6422                	ld	s0,8(sp)
    80001a22:	0141                	addi	sp,sp,16
    80001a24:	8082                	ret

0000000080001a26 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a26:	1101                	addi	sp,sp,-32
    80001a28:	ec06                	sd	ra,24(sp)
    80001a2a:	e822                	sd	s0,16(sp)
    80001a2c:	e426                	sd	s1,8(sp)
    80001a2e:	1000                	addi	s0,sp,32
  push_off();
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	168080e7          	jalr	360(ra) # 80000b98 <push_off>
    80001a38:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a3a:	2781                	sext.w	a5,a5
    80001a3c:	079e                	slli	a5,a5,0x7
    80001a3e:	00010717          	auipc	a4,0x10
    80001a42:	86270713          	addi	a4,a4,-1950 # 800112a0 <pid_lock>
    80001a46:	97ba                	add	a5,a5,a4
    80001a48:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	1ee080e7          	jalr	494(ra) # 80000c38 <pop_off>
  return p;
}
    80001a52:	8526                	mv	a0,s1
    80001a54:	60e2                	ld	ra,24(sp)
    80001a56:	6442                	ld	s0,16(sp)
    80001a58:	64a2                	ld	s1,8(sp)
    80001a5a:	6105                	addi	sp,sp,32
    80001a5c:	8082                	ret

0000000080001a5e <syscall_count_print>:
void syscall_count_print(void){
    80001a5e:	1141                	addi	sp,sp,-16
    80001a60:	e406                	sd	ra,8(sp)
    80001a62:	e022                	sd	s0,0(sp)
    80001a64:	0800                	addi	s0,sp,16
	struct proc *p = myproc();
    80001a66:	00000097          	auipc	ra,0x0
    80001a6a:	fc0080e7          	jalr	-64(ra) # 80001a26 <myproc>
	printf("Number of system calls made by the current process: %d\n", syscallCount);
    80001a6e:	16852583          	lw	a1,360(a0)
    80001a72:	00006517          	auipc	a0,0x6
    80001a76:	7d650513          	addi	a0,a0,2006 # 80008248 <digits+0x208>
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	b0e080e7          	jalr	-1266(ra) # 80000588 <printf>
}
    80001a82:	60a2                	ld	ra,8(sp)
    80001a84:	6402                	ld	s0,0(sp)
    80001a86:	0141                	addi	sp,sp,16
    80001a88:	8082                	ret

0000000080001a8a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a8a:	1141                	addi	sp,sp,-16
    80001a8c:	e406                	sd	ra,8(sp)
    80001a8e:	e022                	sd	s0,0(sp)
    80001a90:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a92:	00000097          	auipc	ra,0x0
    80001a96:	f94080e7          	jalr	-108(ra) # 80001a26 <myproc>
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	1fe080e7          	jalr	510(ra) # 80000c98 <release>

  if (first) {
    80001aa2:	00007797          	auipc	a5,0x7
    80001aa6:	e0e7a783          	lw	a5,-498(a5) # 800088b0 <first.1697>
    80001aaa:	eb89                	bnez	a5,80001abc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001aac:	00001097          	auipc	ra,0x1
    80001ab0:	c0e080e7          	jalr	-1010(ra) # 800026ba <usertrapret>
}
    80001ab4:	60a2                	ld	ra,8(sp)
    80001ab6:	6402                	ld	s0,0(sp)
    80001ab8:	0141                	addi	sp,sp,16
    80001aba:	8082                	ret
    first = 0;
    80001abc:	00007797          	auipc	a5,0x7
    80001ac0:	de07aa23          	sw	zero,-524(a5) # 800088b0 <first.1697>
    fsinit(ROOTDEV);
    80001ac4:	4505                	li	a0,1
    80001ac6:	00002097          	auipc	ra,0x2
    80001aca:	9a8080e7          	jalr	-1624(ra) # 8000346e <fsinit>
    80001ace:	bff9                	j	80001aac <forkret+0x22>

0000000080001ad0 <allocpid>:
allocpid() {
    80001ad0:	1101                	addi	sp,sp,-32
    80001ad2:	ec06                	sd	ra,24(sp)
    80001ad4:	e822                	sd	s0,16(sp)
    80001ad6:	e426                	sd	s1,8(sp)
    80001ad8:	e04a                	sd	s2,0(sp)
    80001ada:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001adc:	0000f917          	auipc	s2,0xf
    80001ae0:	7c490913          	addi	s2,s2,1988 # 800112a0 <pid_lock>
    80001ae4:	854a                	mv	a0,s2
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	0fe080e7          	jalr	254(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001aee:	00007797          	auipc	a5,0x7
    80001af2:	dc678793          	addi	a5,a5,-570 # 800088b4 <nextpid>
    80001af6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001af8:	0014871b          	addiw	a4,s1,1
    80001afc:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001afe:	854a                	mv	a0,s2
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	198080e7          	jalr	408(ra) # 80000c98 <release>
}
    80001b08:	8526                	mv	a0,s1
    80001b0a:	60e2                	ld	ra,24(sp)
    80001b0c:	6442                	ld	s0,16(sp)
    80001b0e:	64a2                	ld	s1,8(sp)
    80001b10:	6902                	ld	s2,0(sp)
    80001b12:	6105                	addi	sp,sp,32
    80001b14:	8082                	ret

0000000080001b16 <proc_pagetable>:
{
    80001b16:	1101                	addi	sp,sp,-32
    80001b18:	ec06                	sd	ra,24(sp)
    80001b1a:	e822                	sd	s0,16(sp)
    80001b1c:	e426                	sd	s1,8(sp)
    80001b1e:	e04a                	sd	s2,0(sp)
    80001b20:	1000                	addi	s0,sp,32
    80001b22:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	816080e7          	jalr	-2026(ra) # 8000133a <uvmcreate>
    80001b2c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b2e:	c121                	beqz	a0,80001b6e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b30:	4729                	li	a4,10
    80001b32:	00005697          	auipc	a3,0x5
    80001b36:	4ce68693          	addi	a3,a3,1230 # 80007000 <_trampoline>
    80001b3a:	6605                	lui	a2,0x1
    80001b3c:	040005b7          	lui	a1,0x4000
    80001b40:	15fd                	addi	a1,a1,-1
    80001b42:	05b2                	slli	a1,a1,0xc
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	56c080e7          	jalr	1388(ra) # 800010b0 <mappages>
    80001b4c:	02054863          	bltz	a0,80001b7c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b50:	4719                	li	a4,6
    80001b52:	05893683          	ld	a3,88(s2)
    80001b56:	6605                	lui	a2,0x1
    80001b58:	020005b7          	lui	a1,0x2000
    80001b5c:	15fd                	addi	a1,a1,-1
    80001b5e:	05b6                	slli	a1,a1,0xd
    80001b60:	8526                	mv	a0,s1
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	54e080e7          	jalr	1358(ra) # 800010b0 <mappages>
    80001b6a:	02054163          	bltz	a0,80001b8c <proc_pagetable+0x76>
}
    80001b6e:	8526                	mv	a0,s1
    80001b70:	60e2                	ld	ra,24(sp)
    80001b72:	6442                	ld	s0,16(sp)
    80001b74:	64a2                	ld	s1,8(sp)
    80001b76:	6902                	ld	s2,0(sp)
    80001b78:	6105                	addi	sp,sp,32
    80001b7a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b7c:	4581                	li	a1,0
    80001b7e:	8526                	mv	a0,s1
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	9b6080e7          	jalr	-1610(ra) # 80001536 <uvmfree>
    return 0;
    80001b88:	4481                	li	s1,0
    80001b8a:	b7d5                	j	80001b6e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b8c:	4681                	li	a3,0
    80001b8e:	4605                	li	a2,1
    80001b90:	040005b7          	lui	a1,0x4000
    80001b94:	15fd                	addi	a1,a1,-1
    80001b96:	05b2                	slli	a1,a1,0xc
    80001b98:	8526                	mv	a0,s1
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	6dc080e7          	jalr	1756(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ba2:	4581                	li	a1,0
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	00000097          	auipc	ra,0x0
    80001baa:	990080e7          	jalr	-1648(ra) # 80001536 <uvmfree>
    return 0;
    80001bae:	4481                	li	s1,0
    80001bb0:	bf7d                	j	80001b6e <proc_pagetable+0x58>

0000000080001bb2 <proc_freepagetable>:
{
    80001bb2:	1101                	addi	sp,sp,-32
    80001bb4:	ec06                	sd	ra,24(sp)
    80001bb6:	e822                	sd	s0,16(sp)
    80001bb8:	e426                	sd	s1,8(sp)
    80001bba:	e04a                	sd	s2,0(sp)
    80001bbc:	1000                	addi	s0,sp,32
    80001bbe:	84aa                	mv	s1,a0
    80001bc0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bc2:	4681                	li	a3,0
    80001bc4:	4605                	li	a2,1
    80001bc6:	040005b7          	lui	a1,0x4000
    80001bca:	15fd                	addi	a1,a1,-1
    80001bcc:	05b2                	slli	a1,a1,0xc
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	6a8080e7          	jalr	1704(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bd6:	4681                	li	a3,0
    80001bd8:	4605                	li	a2,1
    80001bda:	020005b7          	lui	a1,0x2000
    80001bde:	15fd                	addi	a1,a1,-1
    80001be0:	05b6                	slli	a1,a1,0xd
    80001be2:	8526                	mv	a0,s1
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	692080e7          	jalr	1682(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bec:	85ca                	mv	a1,s2
    80001bee:	8526                	mv	a0,s1
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	946080e7          	jalr	-1722(ra) # 80001536 <uvmfree>
}
    80001bf8:	60e2                	ld	ra,24(sp)
    80001bfa:	6442                	ld	s0,16(sp)
    80001bfc:	64a2                	ld	s1,8(sp)
    80001bfe:	6902                	ld	s2,0(sp)
    80001c00:	6105                	addi	sp,sp,32
    80001c02:	8082                	ret

0000000080001c04 <freeproc>:
{
    80001c04:	1101                	addi	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	1000                	addi	s0,sp,32
    80001c0e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c10:	6d28                	ld	a0,88(a0)
    80001c12:	c509                	beqz	a0,80001c1c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	de4080e7          	jalr	-540(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001c1c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c20:	68a8                	ld	a0,80(s1)
    80001c22:	c511                	beqz	a0,80001c2e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c24:	64ac                	ld	a1,72(s1)
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	f8c080e7          	jalr	-116(ra) # 80001bb2 <proc_freepagetable>
  p->pagetable = 0;
    80001c2e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c32:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c36:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c3a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c3e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c42:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c46:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c4a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c4e:	0004ac23          	sw	zero,24(s1)
}
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6105                	addi	sp,sp,32
    80001c5a:	8082                	ret

0000000080001c5c <allocproc>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	00010497          	auipc	s1,0x10
    80001c6c:	a6848493          	addi	s1,s1,-1432 # 800116d0 <proc>
    80001c70:	00015917          	auipc	s2,0x15
    80001c74:	66090913          	addi	s2,s2,1632 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	f6a080e7          	jalr	-150(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c82:	4c9c                	lw	a5,24(s1)
    80001c84:	cf81                	beqz	a5,80001c9c <allocproc+0x40>
      release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	010080e7          	jalr	16(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c90:	17048493          	addi	s1,s1,368
    80001c94:	ff2492e3          	bne	s1,s2,80001c78 <allocproc+0x1c>
  return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	a899                	j	80001cf0 <allocproc+0x94>
  p->syscallCount = 0;
    80001c9c:	1604b423          	sd	zero,360(s1)
  p->pid = allocpid();
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	e30080e7          	jalr	-464(ra) # 80001ad0 <allocpid>
    80001ca8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001caa:	4785                	li	a5,1
    80001cac:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	e46080e7          	jalr	-442(ra) # 80000af4 <kalloc>
    80001cb6:	892a                	mv	s2,a0
    80001cb8:	eca8                	sd	a0,88(s1)
    80001cba:	c131                	beqz	a0,80001cfe <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	e58080e7          	jalr	-424(ra) # 80001b16 <proc_pagetable>
    80001cc6:	892a                	mv	s2,a0
    80001cc8:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cca:	c531                	beqz	a0,80001d16 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001ccc:	07000613          	li	a2,112
    80001cd0:	4581                	li	a1,0
    80001cd2:	06048513          	addi	a0,s1,96
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	00a080e7          	jalr	10(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001cde:	00000797          	auipc	a5,0x0
    80001ce2:	dac78793          	addi	a5,a5,-596 # 80001a8a <forkret>
    80001ce6:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce8:	60bc                	ld	a5,64(s1)
    80001cea:	6705                	lui	a4,0x1
    80001cec:	97ba                	add	a5,a5,a4
    80001cee:	f4bc                	sd	a5,104(s1)
}
    80001cf0:	8526                	mv	a0,s1
    80001cf2:	60e2                	ld	ra,24(sp)
    80001cf4:	6442                	ld	s0,16(sp)
    80001cf6:	64a2                	ld	s1,8(sp)
    80001cf8:	6902                	ld	s2,0(sp)
    80001cfa:	6105                	addi	sp,sp,32
    80001cfc:	8082                	ret
    freeproc(p);
    80001cfe:	8526                	mv	a0,s1
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	f04080e7          	jalr	-252(ra) # 80001c04 <freeproc>
    release(&p->lock);
    80001d08:	8526                	mv	a0,s1
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	f8e080e7          	jalr	-114(ra) # 80000c98 <release>
    return 0;
    80001d12:	84ca                	mv	s1,s2
    80001d14:	bff1                	j	80001cf0 <allocproc+0x94>
    freeproc(p);
    80001d16:	8526                	mv	a0,s1
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	eec080e7          	jalr	-276(ra) # 80001c04 <freeproc>
    release(&p->lock);
    80001d20:	8526                	mv	a0,s1
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	f76080e7          	jalr	-138(ra) # 80000c98 <release>
    return 0;
    80001d2a:	84ca                	mv	s1,s2
    80001d2c:	b7d1                	j	80001cf0 <allocproc+0x94>

0000000080001d2e <userinit>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	f24080e7          	jalr	-220(ra) # 80001c5c <allocproc>
    80001d40:	84aa                	mv	s1,a0
  initproc = p;
    80001d42:	00007797          	auipc	a5,0x7
    80001d46:	2ea7b323          	sd	a0,742(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d4a:	03400613          	li	a2,52
    80001d4e:	00007597          	auipc	a1,0x7
    80001d52:	b7258593          	addi	a1,a1,-1166 # 800088c0 <initcode>
    80001d56:	6928                	ld	a0,80(a0)
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	610080e7          	jalr	1552(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d60:	6785                	lui	a5,0x1
    80001d62:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d64:	6cb8                	ld	a4,88(s1)
    80001d66:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d6a:	6cb8                	ld	a4,88(s1)
    80001d6c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d6e:	4641                	li	a2,16
    80001d70:	00006597          	auipc	a1,0x6
    80001d74:	51058593          	addi	a1,a1,1296 # 80008280 <digits+0x240>
    80001d78:	15848513          	addi	a0,s1,344
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	0b6080e7          	jalr	182(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d84:	00006517          	auipc	a0,0x6
    80001d88:	50c50513          	addi	a0,a0,1292 # 80008290 <digits+0x250>
    80001d8c:	00002097          	auipc	ra,0x2
    80001d90:	110080e7          	jalr	272(ra) # 80003e9c <namei>
    80001d94:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d98:	478d                	li	a5,3
    80001d9a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	efa080e7          	jalr	-262(ra) # 80000c98 <release>
}
    80001da6:	60e2                	ld	ra,24(sp)
    80001da8:	6442                	ld	s0,16(sp)
    80001daa:	64a2                	ld	s1,8(sp)
    80001dac:	6105                	addi	sp,sp,32
    80001dae:	8082                	ret

0000000080001db0 <growproc>:
{
    80001db0:	1101                	addi	sp,sp,-32
    80001db2:	ec06                	sd	ra,24(sp)
    80001db4:	e822                	sd	s0,16(sp)
    80001db6:	e426                	sd	s1,8(sp)
    80001db8:	e04a                	sd	s2,0(sp)
    80001dba:	1000                	addi	s0,sp,32
    80001dbc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	c68080e7          	jalr	-920(ra) # 80001a26 <myproc>
    80001dc6:	892a                	mv	s2,a0
  sz = p->sz;
    80001dc8:	652c                	ld	a1,72(a0)
    80001dca:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dce:	00904f63          	bgtz	s1,80001dec <growproc+0x3c>
  } else if(n < 0){
    80001dd2:	0204cc63          	bltz	s1,80001e0a <growproc+0x5a>
  p->sz = sz;
    80001dd6:	1602                	slli	a2,a2,0x20
    80001dd8:	9201                	srli	a2,a2,0x20
    80001dda:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dde:	4501                	li	a0,0
}
    80001de0:	60e2                	ld	ra,24(sp)
    80001de2:	6442                	ld	s0,16(sp)
    80001de4:	64a2                	ld	s1,8(sp)
    80001de6:	6902                	ld	s2,0(sp)
    80001de8:	6105                	addi	sp,sp,32
    80001dea:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dec:	9e25                	addw	a2,a2,s1
    80001dee:	1602                	slli	a2,a2,0x20
    80001df0:	9201                	srli	a2,a2,0x20
    80001df2:	1582                	slli	a1,a1,0x20
    80001df4:	9181                	srli	a1,a1,0x20
    80001df6:	6928                	ld	a0,80(a0)
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	62a080e7          	jalr	1578(ra) # 80001422 <uvmalloc>
    80001e00:	0005061b          	sext.w	a2,a0
    80001e04:	fa69                	bnez	a2,80001dd6 <growproc+0x26>
      return -1;
    80001e06:	557d                	li	a0,-1
    80001e08:	bfe1                	j	80001de0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e0a:	9e25                	addw	a2,a2,s1
    80001e0c:	1602                	slli	a2,a2,0x20
    80001e0e:	9201                	srli	a2,a2,0x20
    80001e10:	1582                	slli	a1,a1,0x20
    80001e12:	9181                	srli	a1,a1,0x20
    80001e14:	6928                	ld	a0,80(a0)
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	5c4080e7          	jalr	1476(ra) # 800013da <uvmdealloc>
    80001e1e:	0005061b          	sext.w	a2,a0
    80001e22:	bf55                	j	80001dd6 <growproc+0x26>

0000000080001e24 <fork>:
{
    80001e24:	7179                	addi	sp,sp,-48
    80001e26:	f406                	sd	ra,40(sp)
    80001e28:	f022                	sd	s0,32(sp)
    80001e2a:	ec26                	sd	s1,24(sp)
    80001e2c:	e84a                	sd	s2,16(sp)
    80001e2e:	e44e                	sd	s3,8(sp)
    80001e30:	e052                	sd	s4,0(sp)
    80001e32:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e34:	00000097          	auipc	ra,0x0
    80001e38:	bf2080e7          	jalr	-1038(ra) # 80001a26 <myproc>
    80001e3c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	e1e080e7          	jalr	-482(ra) # 80001c5c <allocproc>
    80001e46:	10050b63          	beqz	a0,80001f5c <fork+0x138>
    80001e4a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e4c:	04893603          	ld	a2,72(s2)
    80001e50:	692c                	ld	a1,80(a0)
    80001e52:	05093503          	ld	a0,80(s2)
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	718080e7          	jalr	1816(ra) # 8000156e <uvmcopy>
    80001e5e:	04054663          	bltz	a0,80001eaa <fork+0x86>
  np->sz = p->sz;
    80001e62:	04893783          	ld	a5,72(s2)
    80001e66:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e6a:	05893683          	ld	a3,88(s2)
    80001e6e:	87b6                	mv	a5,a3
    80001e70:	0589b703          	ld	a4,88(s3)
    80001e74:	12068693          	addi	a3,a3,288
    80001e78:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e7c:	6788                	ld	a0,8(a5)
    80001e7e:	6b8c                	ld	a1,16(a5)
    80001e80:	6f90                	ld	a2,24(a5)
    80001e82:	01073023          	sd	a6,0(a4)
    80001e86:	e708                	sd	a0,8(a4)
    80001e88:	eb0c                	sd	a1,16(a4)
    80001e8a:	ef10                	sd	a2,24(a4)
    80001e8c:	02078793          	addi	a5,a5,32
    80001e90:	02070713          	addi	a4,a4,32
    80001e94:	fed792e3          	bne	a5,a3,80001e78 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e98:	0589b783          	ld	a5,88(s3)
    80001e9c:	0607b823          	sd	zero,112(a5)
    80001ea0:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ea4:	15000a13          	li	s4,336
    80001ea8:	a03d                	j	80001ed6 <fork+0xb2>
    freeproc(np);
    80001eaa:	854e                	mv	a0,s3
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	d58080e7          	jalr	-680(ra) # 80001c04 <freeproc>
    release(&np->lock);
    80001eb4:	854e                	mv	a0,s3
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	de2080e7          	jalr	-542(ra) # 80000c98 <release>
    return -1;
    80001ebe:	5a7d                	li	s4,-1
    80001ec0:	a069                	j	80001f4a <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ec2:	00002097          	auipc	ra,0x2
    80001ec6:	670080e7          	jalr	1648(ra) # 80004532 <filedup>
    80001eca:	009987b3          	add	a5,s3,s1
    80001ece:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ed0:	04a1                	addi	s1,s1,8
    80001ed2:	01448763          	beq	s1,s4,80001ee0 <fork+0xbc>
    if(p->ofile[i])
    80001ed6:	009907b3          	add	a5,s2,s1
    80001eda:	6388                	ld	a0,0(a5)
    80001edc:	f17d                	bnez	a0,80001ec2 <fork+0x9e>
    80001ede:	bfcd                	j	80001ed0 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001ee0:	15093503          	ld	a0,336(s2)
    80001ee4:	00001097          	auipc	ra,0x1
    80001ee8:	7c4080e7          	jalr	1988(ra) # 800036a8 <idup>
    80001eec:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ef0:	4641                	li	a2,16
    80001ef2:	15890593          	addi	a1,s2,344
    80001ef6:	15898513          	addi	a0,s3,344
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	f38080e7          	jalr	-200(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f02:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f06:	854e                	mv	a0,s3
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d90080e7          	jalr	-624(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f10:	0000f497          	auipc	s1,0xf
    80001f14:	3a848493          	addi	s1,s1,936 # 800112b8 <wait_lock>
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	cca080e7          	jalr	-822(ra) # 80000be4 <acquire>
  np->parent = p;
    80001f22:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d70080e7          	jalr	-656(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f30:	854e                	mv	a0,s3
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	cb2080e7          	jalr	-846(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f3a:	478d                	li	a5,3
    80001f3c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f40:	854e                	mv	a0,s3
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d56080e7          	jalr	-682(ra) # 80000c98 <release>
}
    80001f4a:	8552                	mv	a0,s4
    80001f4c:	70a2                	ld	ra,40(sp)
    80001f4e:	7402                	ld	s0,32(sp)
    80001f50:	64e2                	ld	s1,24(sp)
    80001f52:	6942                	ld	s2,16(sp)
    80001f54:	69a2                	ld	s3,8(sp)
    80001f56:	6a02                	ld	s4,0(sp)
    80001f58:	6145                	addi	sp,sp,48
    80001f5a:	8082                	ret
    return -1;
    80001f5c:	5a7d                	li	s4,-1
    80001f5e:	b7f5                	j	80001f4a <fork+0x126>

0000000080001f60 <scheduler>:
{
    80001f60:	7139                	addi	sp,sp,-64
    80001f62:	fc06                	sd	ra,56(sp)
    80001f64:	f822                	sd	s0,48(sp)
    80001f66:	f426                	sd	s1,40(sp)
    80001f68:	f04a                	sd	s2,32(sp)
    80001f6a:	ec4e                	sd	s3,24(sp)
    80001f6c:	e852                	sd	s4,16(sp)
    80001f6e:	e456                	sd	s5,8(sp)
    80001f70:	e05a                	sd	s6,0(sp)
    80001f72:	0080                	addi	s0,sp,64
    80001f74:	8792                	mv	a5,tp
  int id = r_tp();
    80001f76:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f78:	00779a93          	slli	s5,a5,0x7
    80001f7c:	0000f717          	auipc	a4,0xf
    80001f80:	32470713          	addi	a4,a4,804 # 800112a0 <pid_lock>
    80001f84:	9756                	add	a4,a4,s5
    80001f86:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f8a:	0000f717          	auipc	a4,0xf
    80001f8e:	34e70713          	addi	a4,a4,846 # 800112d8 <cpus+0x8>
    80001f92:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f94:	498d                	li	s3,3
        p->state = RUNNING;
    80001f96:	4b11                	li	s6,4
        c->proc = p;
    80001f98:	079e                	slli	a5,a5,0x7
    80001f9a:	0000fa17          	auipc	s4,0xf
    80001f9e:	306a0a13          	addi	s4,s4,774 # 800112a0 <pid_lock>
    80001fa2:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa4:	00015917          	auipc	s2,0x15
    80001fa8:	32c90913          	addi	s2,s2,812 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fb0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fb4:	10079073          	csrw	sstatus,a5
    80001fb8:	0000f497          	auipc	s1,0xf
    80001fbc:	71848493          	addi	s1,s1,1816 # 800116d0 <proc>
    80001fc0:	a03d                	j	80001fee <scheduler+0x8e>
        p->state = RUNNING;
    80001fc2:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fc6:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fca:	06048593          	addi	a1,s1,96
    80001fce:	8556                	mv	a0,s5
    80001fd0:	00000097          	auipc	ra,0x0
    80001fd4:	640080e7          	jalr	1600(ra) # 80002610 <swtch>
        c->proc = 0;
    80001fd8:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001fdc:	8526                	mv	a0,s1
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	cba080e7          	jalr	-838(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe6:	17048493          	addi	s1,s1,368
    80001fea:	fd2481e3          	beq	s1,s2,80001fac <scheduler+0x4c>
      acquire(&p->lock);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	bf4080e7          	jalr	-1036(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001ff8:	4c9c                	lw	a5,24(s1)
    80001ffa:	ff3791e3          	bne	a5,s3,80001fdc <scheduler+0x7c>
    80001ffe:	b7d1                	j	80001fc2 <scheduler+0x62>

0000000080002000 <sched>:
{
    80002000:	7179                	addi	sp,sp,-48
    80002002:	f406                	sd	ra,40(sp)
    80002004:	f022                	sd	s0,32(sp)
    80002006:	ec26                	sd	s1,24(sp)
    80002008:	e84a                	sd	s2,16(sp)
    8000200a:	e44e                	sd	s3,8(sp)
    8000200c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000200e:	00000097          	auipc	ra,0x0
    80002012:	a18080e7          	jalr	-1512(ra) # 80001a26 <myproc>
    80002016:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	b52080e7          	jalr	-1198(ra) # 80000b6a <holding>
    80002020:	c93d                	beqz	a0,80002096 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002022:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002024:	2781                	sext.w	a5,a5
    80002026:	079e                	slli	a5,a5,0x7
    80002028:	0000f717          	auipc	a4,0xf
    8000202c:	27870713          	addi	a4,a4,632 # 800112a0 <pid_lock>
    80002030:	97ba                	add	a5,a5,a4
    80002032:	0a87a703          	lw	a4,168(a5)
    80002036:	4785                	li	a5,1
    80002038:	06f71763          	bne	a4,a5,800020a6 <sched+0xa6>
  if(p->state == RUNNING)
    8000203c:	4c98                	lw	a4,24(s1)
    8000203e:	4791                	li	a5,4
    80002040:	06f70b63          	beq	a4,a5,800020b6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002044:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002048:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000204a:	efb5                	bnez	a5,800020c6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000204c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000204e:	0000f917          	auipc	s2,0xf
    80002052:	25290913          	addi	s2,s2,594 # 800112a0 <pid_lock>
    80002056:	2781                	sext.w	a5,a5
    80002058:	079e                	slli	a5,a5,0x7
    8000205a:	97ca                	add	a5,a5,s2
    8000205c:	0ac7a983          	lw	s3,172(a5)
    80002060:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002062:	2781                	sext.w	a5,a5
    80002064:	079e                	slli	a5,a5,0x7
    80002066:	0000f597          	auipc	a1,0xf
    8000206a:	27258593          	addi	a1,a1,626 # 800112d8 <cpus+0x8>
    8000206e:	95be                	add	a1,a1,a5
    80002070:	06048513          	addi	a0,s1,96
    80002074:	00000097          	auipc	ra,0x0
    80002078:	59c080e7          	jalr	1436(ra) # 80002610 <swtch>
    8000207c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000207e:	2781                	sext.w	a5,a5
    80002080:	079e                	slli	a5,a5,0x7
    80002082:	97ca                	add	a5,a5,s2
    80002084:	0b37a623          	sw	s3,172(a5)
}
    80002088:	70a2                	ld	ra,40(sp)
    8000208a:	7402                	ld	s0,32(sp)
    8000208c:	64e2                	ld	s1,24(sp)
    8000208e:	6942                	ld	s2,16(sp)
    80002090:	69a2                	ld	s3,8(sp)
    80002092:	6145                	addi	sp,sp,48
    80002094:	8082                	ret
    panic("sched p->lock");
    80002096:	00006517          	auipc	a0,0x6
    8000209a:	20250513          	addi	a0,a0,514 # 80008298 <digits+0x258>
    8000209e:	ffffe097          	auipc	ra,0xffffe
    800020a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    panic("sched locks");
    800020a6:	00006517          	auipc	a0,0x6
    800020aa:	20250513          	addi	a0,a0,514 # 800082a8 <digits+0x268>
    800020ae:	ffffe097          	auipc	ra,0xffffe
    800020b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>
    panic("sched running");
    800020b6:	00006517          	auipc	a0,0x6
    800020ba:	20250513          	addi	a0,a0,514 # 800082b8 <digits+0x278>
    800020be:	ffffe097          	auipc	ra,0xffffe
    800020c2:	480080e7          	jalr	1152(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020c6:	00006517          	auipc	a0,0x6
    800020ca:	20250513          	addi	a0,a0,514 # 800082c8 <digits+0x288>
    800020ce:	ffffe097          	auipc	ra,0xffffe
    800020d2:	470080e7          	jalr	1136(ra) # 8000053e <panic>

00000000800020d6 <yield>:
{
    800020d6:	1101                	addi	sp,sp,-32
    800020d8:	ec06                	sd	ra,24(sp)
    800020da:	e822                	sd	s0,16(sp)
    800020dc:	e426                	sd	s1,8(sp)
    800020de:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	946080e7          	jalr	-1722(ra) # 80001a26 <myproc>
    800020e8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	afa080e7          	jalr	-1286(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020f2:	478d                	li	a5,3
    800020f4:	cc9c                	sw	a5,24(s1)
  sched();
    800020f6:	00000097          	auipc	ra,0x0
    800020fa:	f0a080e7          	jalr	-246(ra) # 80002000 <sched>
  release(&p->lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	b98080e7          	jalr	-1128(ra) # 80000c98 <release>
}
    80002108:	60e2                	ld	ra,24(sp)
    8000210a:	6442                	ld	s0,16(sp)
    8000210c:	64a2                	ld	s1,8(sp)
    8000210e:	6105                	addi	sp,sp,32
    80002110:	8082                	ret

0000000080002112 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002112:	7179                	addi	sp,sp,-48
    80002114:	f406                	sd	ra,40(sp)
    80002116:	f022                	sd	s0,32(sp)
    80002118:	ec26                	sd	s1,24(sp)
    8000211a:	e84a                	sd	s2,16(sp)
    8000211c:	e44e                	sd	s3,8(sp)
    8000211e:	1800                	addi	s0,sp,48
    80002120:	89aa                	mv	s3,a0
    80002122:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002124:	00000097          	auipc	ra,0x0
    80002128:	902080e7          	jalr	-1790(ra) # 80001a26 <myproc>
    8000212c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	ab6080e7          	jalr	-1354(ra) # 80000be4 <acquire>
  release(lk);
    80002136:	854a                	mv	a0,s2
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b60080e7          	jalr	-1184(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002140:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002144:	4789                	li	a5,2
    80002146:	cc9c                	sw	a5,24(s1)

  sched();
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	eb8080e7          	jalr	-328(ra) # 80002000 <sched>

  // Tidy up.
  p->chan = 0;
    80002150:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b42080e7          	jalr	-1214(ra) # 80000c98 <release>
  acquire(lk);
    8000215e:	854a                	mv	a0,s2
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	a84080e7          	jalr	-1404(ra) # 80000be4 <acquire>
}
    80002168:	70a2                	ld	ra,40(sp)
    8000216a:	7402                	ld	s0,32(sp)
    8000216c:	64e2                	ld	s1,24(sp)
    8000216e:	6942                	ld	s2,16(sp)
    80002170:	69a2                	ld	s3,8(sp)
    80002172:	6145                	addi	sp,sp,48
    80002174:	8082                	ret

0000000080002176 <wait>:
{
    80002176:	715d                	addi	sp,sp,-80
    80002178:	e486                	sd	ra,72(sp)
    8000217a:	e0a2                	sd	s0,64(sp)
    8000217c:	fc26                	sd	s1,56(sp)
    8000217e:	f84a                	sd	s2,48(sp)
    80002180:	f44e                	sd	s3,40(sp)
    80002182:	f052                	sd	s4,32(sp)
    80002184:	ec56                	sd	s5,24(sp)
    80002186:	e85a                	sd	s6,16(sp)
    80002188:	e45e                	sd	s7,8(sp)
    8000218a:	e062                	sd	s8,0(sp)
    8000218c:	0880                	addi	s0,sp,80
    8000218e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002190:	00000097          	auipc	ra,0x0
    80002194:	896080e7          	jalr	-1898(ra) # 80001a26 <myproc>
    80002198:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000219a:	0000f517          	auipc	a0,0xf
    8000219e:	11e50513          	addi	a0,a0,286 # 800112b8 <wait_lock>
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	a42080e7          	jalr	-1470(ra) # 80000be4 <acquire>
    havekids = 0;
    800021aa:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800021ac:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800021ae:	00015997          	auipc	s3,0x15
    800021b2:	12298993          	addi	s3,s3,290 # 800172d0 <tickslock>
        havekids = 1;
    800021b6:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021b8:	0000fc17          	auipc	s8,0xf
    800021bc:	100c0c13          	addi	s8,s8,256 # 800112b8 <wait_lock>
    havekids = 0;
    800021c0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800021c2:	0000f497          	auipc	s1,0xf
    800021c6:	50e48493          	addi	s1,s1,1294 # 800116d0 <proc>
    800021ca:	a0bd                	j	80002238 <wait+0xc2>
          pid = np->pid;
    800021cc:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021d0:	000b0e63          	beqz	s6,800021ec <wait+0x76>
    800021d4:	4691                	li	a3,4
    800021d6:	02c48613          	addi	a2,s1,44
    800021da:	85da                	mv	a1,s6
    800021dc:	05093503          	ld	a0,80(s2)
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	492080e7          	jalr	1170(ra) # 80001672 <copyout>
    800021e8:	02054563          	bltz	a0,80002212 <wait+0x9c>
          freeproc(np);
    800021ec:	8526                	mv	a0,s1
    800021ee:	00000097          	auipc	ra,0x0
    800021f2:	a16080e7          	jalr	-1514(ra) # 80001c04 <freeproc>
          release(&np->lock);
    800021f6:	8526                	mv	a0,s1
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	aa0080e7          	jalr	-1376(ra) # 80000c98 <release>
          release(&wait_lock);
    80002200:	0000f517          	auipc	a0,0xf
    80002204:	0b850513          	addi	a0,a0,184 # 800112b8 <wait_lock>
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	a90080e7          	jalr	-1392(ra) # 80000c98 <release>
          return pid;
    80002210:	a09d                	j	80002276 <wait+0x100>
            release(&np->lock);
    80002212:	8526                	mv	a0,s1
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	a84080e7          	jalr	-1404(ra) # 80000c98 <release>
            release(&wait_lock);
    8000221c:	0000f517          	auipc	a0,0xf
    80002220:	09c50513          	addi	a0,a0,156 # 800112b8 <wait_lock>
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	a74080e7          	jalr	-1420(ra) # 80000c98 <release>
            return -1;
    8000222c:	59fd                	li	s3,-1
    8000222e:	a0a1                	j	80002276 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002230:	17048493          	addi	s1,s1,368
    80002234:	03348463          	beq	s1,s3,8000225c <wait+0xe6>
      if(np->parent == p){
    80002238:	7c9c                	ld	a5,56(s1)
    8000223a:	ff279be3          	bne	a5,s2,80002230 <wait+0xba>
        acquire(&np->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	9a4080e7          	jalr	-1628(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002248:	4c9c                	lw	a5,24(s1)
    8000224a:	f94781e3          	beq	a5,s4,800021cc <wait+0x56>
        release(&np->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a48080e7          	jalr	-1464(ra) # 80000c98 <release>
        havekids = 1;
    80002258:	8756                	mv	a4,s5
    8000225a:	bfd9                	j	80002230 <wait+0xba>
    if(!havekids || p->killed){
    8000225c:	c701                	beqz	a4,80002264 <wait+0xee>
    8000225e:	02892783          	lw	a5,40(s2)
    80002262:	c79d                	beqz	a5,80002290 <wait+0x11a>
      release(&wait_lock);
    80002264:	0000f517          	auipc	a0,0xf
    80002268:	05450513          	addi	a0,a0,84 # 800112b8 <wait_lock>
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a2c080e7          	jalr	-1492(ra) # 80000c98 <release>
      return -1;
    80002274:	59fd                	li	s3,-1
}
    80002276:	854e                	mv	a0,s3
    80002278:	60a6                	ld	ra,72(sp)
    8000227a:	6406                	ld	s0,64(sp)
    8000227c:	74e2                	ld	s1,56(sp)
    8000227e:	7942                	ld	s2,48(sp)
    80002280:	79a2                	ld	s3,40(sp)
    80002282:	7a02                	ld	s4,32(sp)
    80002284:	6ae2                	ld	s5,24(sp)
    80002286:	6b42                	ld	s6,16(sp)
    80002288:	6ba2                	ld	s7,8(sp)
    8000228a:	6c02                	ld	s8,0(sp)
    8000228c:	6161                	addi	sp,sp,80
    8000228e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002290:	85e2                	mv	a1,s8
    80002292:	854a                	mv	a0,s2
    80002294:	00000097          	auipc	ra,0x0
    80002298:	e7e080e7          	jalr	-386(ra) # 80002112 <sleep>
    havekids = 0;
    8000229c:	b715                	j	800021c0 <wait+0x4a>

000000008000229e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000229e:	7139                	addi	sp,sp,-64
    800022a0:	fc06                	sd	ra,56(sp)
    800022a2:	f822                	sd	s0,48(sp)
    800022a4:	f426                	sd	s1,40(sp)
    800022a6:	f04a                	sd	s2,32(sp)
    800022a8:	ec4e                	sd	s3,24(sp)
    800022aa:	e852                	sd	s4,16(sp)
    800022ac:	e456                	sd	s5,8(sp)
    800022ae:	0080                	addi	s0,sp,64
    800022b0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022b2:	0000f497          	auipc	s1,0xf
    800022b6:	41e48493          	addi	s1,s1,1054 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022ba:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022bc:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022be:	00015917          	auipc	s2,0x15
    800022c2:	01290913          	addi	s2,s2,18 # 800172d0 <tickslock>
    800022c6:	a821                	j	800022de <wakeup+0x40>
        p->state = RUNNABLE;
    800022c8:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800022cc:	8526                	mv	a0,s1
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	9ca080e7          	jalr	-1590(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022d6:	17048493          	addi	s1,s1,368
    800022da:	03248463          	beq	s1,s2,80002302 <wakeup+0x64>
    if(p != myproc()){
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	748080e7          	jalr	1864(ra) # 80001a26 <myproc>
    800022e6:	fea488e3          	beq	s1,a0,800022d6 <wakeup+0x38>
      acquire(&p->lock);
    800022ea:	8526                	mv	a0,s1
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	8f8080e7          	jalr	-1800(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022f4:	4c9c                	lw	a5,24(s1)
    800022f6:	fd379be3          	bne	a5,s3,800022cc <wakeup+0x2e>
    800022fa:	709c                	ld	a5,32(s1)
    800022fc:	fd4798e3          	bne	a5,s4,800022cc <wakeup+0x2e>
    80002300:	b7e1                	j	800022c8 <wakeup+0x2a>
    }
  }
}
    80002302:	70e2                	ld	ra,56(sp)
    80002304:	7442                	ld	s0,48(sp)
    80002306:	74a2                	ld	s1,40(sp)
    80002308:	7902                	ld	s2,32(sp)
    8000230a:	69e2                	ld	s3,24(sp)
    8000230c:	6a42                	ld	s4,16(sp)
    8000230e:	6aa2                	ld	s5,8(sp)
    80002310:	6121                	addi	sp,sp,64
    80002312:	8082                	ret

0000000080002314 <reparent>:
{
    80002314:	7179                	addi	sp,sp,-48
    80002316:	f406                	sd	ra,40(sp)
    80002318:	f022                	sd	s0,32(sp)
    8000231a:	ec26                	sd	s1,24(sp)
    8000231c:	e84a                	sd	s2,16(sp)
    8000231e:	e44e                	sd	s3,8(sp)
    80002320:	e052                	sd	s4,0(sp)
    80002322:	1800                	addi	s0,sp,48
    80002324:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002326:	0000f497          	auipc	s1,0xf
    8000232a:	3aa48493          	addi	s1,s1,938 # 800116d0 <proc>
      pp->parent = initproc;
    8000232e:	00007a17          	auipc	s4,0x7
    80002332:	cfaa0a13          	addi	s4,s4,-774 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002336:	00015997          	auipc	s3,0x15
    8000233a:	f9a98993          	addi	s3,s3,-102 # 800172d0 <tickslock>
    8000233e:	a029                	j	80002348 <reparent+0x34>
    80002340:	17048493          	addi	s1,s1,368
    80002344:	01348d63          	beq	s1,s3,8000235e <reparent+0x4a>
    if(pp->parent == p){
    80002348:	7c9c                	ld	a5,56(s1)
    8000234a:	ff279be3          	bne	a5,s2,80002340 <reparent+0x2c>
      pp->parent = initproc;
    8000234e:	000a3503          	ld	a0,0(s4)
    80002352:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002354:	00000097          	auipc	ra,0x0
    80002358:	f4a080e7          	jalr	-182(ra) # 8000229e <wakeup>
    8000235c:	b7d5                	j	80002340 <reparent+0x2c>
}
    8000235e:	70a2                	ld	ra,40(sp)
    80002360:	7402                	ld	s0,32(sp)
    80002362:	64e2                	ld	s1,24(sp)
    80002364:	6942                	ld	s2,16(sp)
    80002366:	69a2                	ld	s3,8(sp)
    80002368:	6a02                	ld	s4,0(sp)
    8000236a:	6145                	addi	sp,sp,48
    8000236c:	8082                	ret

000000008000236e <exit>:
{
    8000236e:	7179                	addi	sp,sp,-48
    80002370:	f406                	sd	ra,40(sp)
    80002372:	f022                	sd	s0,32(sp)
    80002374:	ec26                	sd	s1,24(sp)
    80002376:	e84a                	sd	s2,16(sp)
    80002378:	e44e                	sd	s3,8(sp)
    8000237a:	e052                	sd	s4,0(sp)
    8000237c:	1800                	addi	s0,sp,48
    8000237e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	6a6080e7          	jalr	1702(ra) # 80001a26 <myproc>
    80002388:	89aa                	mv	s3,a0
  if(p == initproc)
    8000238a:	00007797          	auipc	a5,0x7
    8000238e:	c9e7b783          	ld	a5,-866(a5) # 80009028 <initproc>
    80002392:	0d050493          	addi	s1,a0,208
    80002396:	15050913          	addi	s2,a0,336
    8000239a:	02a79363          	bne	a5,a0,800023c0 <exit+0x52>
    panic("init exiting");
    8000239e:	00006517          	auipc	a0,0x6
    800023a2:	f4250513          	addi	a0,a0,-190 # 800082e0 <digits+0x2a0>
    800023a6:	ffffe097          	auipc	ra,0xffffe
    800023aa:	198080e7          	jalr	408(ra) # 8000053e <panic>
      fileclose(f);
    800023ae:	00002097          	auipc	ra,0x2
    800023b2:	1d6080e7          	jalr	470(ra) # 80004584 <fileclose>
      p->ofile[fd] = 0;
    800023b6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023ba:	04a1                	addi	s1,s1,8
    800023bc:	01248563          	beq	s1,s2,800023c6 <exit+0x58>
    if(p->ofile[fd]){
    800023c0:	6088                	ld	a0,0(s1)
    800023c2:	f575                	bnez	a0,800023ae <exit+0x40>
    800023c4:	bfdd                	j	800023ba <exit+0x4c>
  begin_op();
    800023c6:	00002097          	auipc	ra,0x2
    800023ca:	cf2080e7          	jalr	-782(ra) # 800040b8 <begin_op>
  iput(p->cwd);
    800023ce:	1509b503          	ld	a0,336(s3)
    800023d2:	00001097          	auipc	ra,0x1
    800023d6:	4ce080e7          	jalr	1230(ra) # 800038a0 <iput>
  end_op();
    800023da:	00002097          	auipc	ra,0x2
    800023de:	d5e080e7          	jalr	-674(ra) # 80004138 <end_op>
  p->cwd = 0;
    800023e2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023e6:	0000f497          	auipc	s1,0xf
    800023ea:	ed248493          	addi	s1,s1,-302 # 800112b8 <wait_lock>
    800023ee:	8526                	mv	a0,s1
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	7f4080e7          	jalr	2036(ra) # 80000be4 <acquire>
  reparent(p);
    800023f8:	854e                	mv	a0,s3
    800023fa:	00000097          	auipc	ra,0x0
    800023fe:	f1a080e7          	jalr	-230(ra) # 80002314 <reparent>
  wakeup(p->parent);
    80002402:	0389b503          	ld	a0,56(s3)
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	e98080e7          	jalr	-360(ra) # 8000229e <wakeup>
  acquire(&p->lock);
    8000240e:	854e                	mv	a0,s3
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	7d4080e7          	jalr	2004(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002418:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000241c:	4795                	li	a5,5
    8000241e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	874080e7          	jalr	-1932(ra) # 80000c98 <release>
  sched();
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	bd4080e7          	jalr	-1068(ra) # 80002000 <sched>
  panic("zombie exit");
    80002434:	00006517          	auipc	a0,0x6
    80002438:	ebc50513          	addi	a0,a0,-324 # 800082f0 <digits+0x2b0>
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	102080e7          	jalr	258(ra) # 8000053e <panic>

0000000080002444 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002444:	7179                	addi	sp,sp,-48
    80002446:	f406                	sd	ra,40(sp)
    80002448:	f022                	sd	s0,32(sp)
    8000244a:	ec26                	sd	s1,24(sp)
    8000244c:	e84a                	sd	s2,16(sp)
    8000244e:	e44e                	sd	s3,8(sp)
    80002450:	1800                	addi	s0,sp,48
    80002452:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002454:	0000f497          	auipc	s1,0xf
    80002458:	27c48493          	addi	s1,s1,636 # 800116d0 <proc>
    8000245c:	00015997          	auipc	s3,0x15
    80002460:	e7498993          	addi	s3,s3,-396 # 800172d0 <tickslock>
    acquire(&p->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	ffffe097          	auipc	ra,0xffffe
    8000246a:	77e080e7          	jalr	1918(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000246e:	589c                	lw	a5,48(s1)
    80002470:	01278d63          	beq	a5,s2,8000248a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	822080e7          	jalr	-2014(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000247e:	17048493          	addi	s1,s1,368
    80002482:	ff3491e3          	bne	s1,s3,80002464 <kill+0x20>
  }
  return -1;
    80002486:	557d                	li	a0,-1
    80002488:	a829                	j	800024a2 <kill+0x5e>
      p->killed = 1;
    8000248a:	4785                	li	a5,1
    8000248c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000248e:	4c98                	lw	a4,24(s1)
    80002490:	4789                	li	a5,2
    80002492:	00f70f63          	beq	a4,a5,800024b0 <kill+0x6c>
      release(&p->lock);
    80002496:	8526                	mv	a0,s1
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	800080e7          	jalr	-2048(ra) # 80000c98 <release>
      return 0;
    800024a0:	4501                	li	a0,0
}
    800024a2:	70a2                	ld	ra,40(sp)
    800024a4:	7402                	ld	s0,32(sp)
    800024a6:	64e2                	ld	s1,24(sp)
    800024a8:	6942                	ld	s2,16(sp)
    800024aa:	69a2                	ld	s3,8(sp)
    800024ac:	6145                	addi	sp,sp,48
    800024ae:	8082                	ret
        p->state = RUNNABLE;
    800024b0:	478d                	li	a5,3
    800024b2:	cc9c                	sw	a5,24(s1)
    800024b4:	b7cd                	j	80002496 <kill+0x52>

00000000800024b6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024b6:	7179                	addi	sp,sp,-48
    800024b8:	f406                	sd	ra,40(sp)
    800024ba:	f022                	sd	s0,32(sp)
    800024bc:	ec26                	sd	s1,24(sp)
    800024be:	e84a                	sd	s2,16(sp)
    800024c0:	e44e                	sd	s3,8(sp)
    800024c2:	e052                	sd	s4,0(sp)
    800024c4:	1800                	addi	s0,sp,48
    800024c6:	84aa                	mv	s1,a0
    800024c8:	892e                	mv	s2,a1
    800024ca:	89b2                	mv	s3,a2
    800024cc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	558080e7          	jalr	1368(ra) # 80001a26 <myproc>
  if(user_dst){
    800024d6:	c08d                	beqz	s1,800024f8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024d8:	86d2                	mv	a3,s4
    800024da:	864e                	mv	a2,s3
    800024dc:	85ca                	mv	a1,s2
    800024de:	6928                	ld	a0,80(a0)
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	192080e7          	jalr	402(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024e8:	70a2                	ld	ra,40(sp)
    800024ea:	7402                	ld	s0,32(sp)
    800024ec:	64e2                	ld	s1,24(sp)
    800024ee:	6942                	ld	s2,16(sp)
    800024f0:	69a2                	ld	s3,8(sp)
    800024f2:	6a02                	ld	s4,0(sp)
    800024f4:	6145                	addi	sp,sp,48
    800024f6:	8082                	ret
    memmove((char *)dst, src, len);
    800024f8:	000a061b          	sext.w	a2,s4
    800024fc:	85ce                	mv	a1,s3
    800024fe:	854a                	mv	a0,s2
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	840080e7          	jalr	-1984(ra) # 80000d40 <memmove>
    return 0;
    80002508:	8526                	mv	a0,s1
    8000250a:	bff9                	j	800024e8 <either_copyout+0x32>

000000008000250c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000250c:	7179                	addi	sp,sp,-48
    8000250e:	f406                	sd	ra,40(sp)
    80002510:	f022                	sd	s0,32(sp)
    80002512:	ec26                	sd	s1,24(sp)
    80002514:	e84a                	sd	s2,16(sp)
    80002516:	e44e                	sd	s3,8(sp)
    80002518:	e052                	sd	s4,0(sp)
    8000251a:	1800                	addi	s0,sp,48
    8000251c:	892a                	mv	s2,a0
    8000251e:	84ae                	mv	s1,a1
    80002520:	89b2                	mv	s3,a2
    80002522:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002524:	fffff097          	auipc	ra,0xfffff
    80002528:	502080e7          	jalr	1282(ra) # 80001a26 <myproc>
  if(user_src){
    8000252c:	c08d                	beqz	s1,8000254e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000252e:	86d2                	mv	a3,s4
    80002530:	864e                	mv	a2,s3
    80002532:	85ca                	mv	a1,s2
    80002534:	6928                	ld	a0,80(a0)
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	1c8080e7          	jalr	456(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000253e:	70a2                	ld	ra,40(sp)
    80002540:	7402                	ld	s0,32(sp)
    80002542:	64e2                	ld	s1,24(sp)
    80002544:	6942                	ld	s2,16(sp)
    80002546:	69a2                	ld	s3,8(sp)
    80002548:	6a02                	ld	s4,0(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000254e:	000a061b          	sext.w	a2,s4
    80002552:	85ce                	mv	a1,s3
    80002554:	854a                	mv	a0,s2
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	7ea080e7          	jalr	2026(ra) # 80000d40 <memmove>
    return 0;
    8000255e:	8526                	mv	a0,s1
    80002560:	bff9                	j	8000253e <either_copyin+0x32>

0000000080002562 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002562:	715d                	addi	sp,sp,-80
    80002564:	e486                	sd	ra,72(sp)
    80002566:	e0a2                	sd	s0,64(sp)
    80002568:	fc26                	sd	s1,56(sp)
    8000256a:	f84a                	sd	s2,48(sp)
    8000256c:	f44e                	sd	s3,40(sp)
    8000256e:	f052                	sd	s4,32(sp)
    80002570:	ec56                	sd	s5,24(sp)
    80002572:	e85a                	sd	s6,16(sp)
    80002574:	e45e                	sd	s7,8(sp)
    80002576:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002578:	00006517          	auipc	a0,0x6
    8000257c:	b5050513          	addi	a0,a0,-1200 # 800080c8 <digits+0x88>
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	008080e7          	jalr	8(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002588:	0000f497          	auipc	s1,0xf
    8000258c:	2a048493          	addi	s1,s1,672 # 80011828 <proc+0x158>
    80002590:	00015917          	auipc	s2,0x15
    80002594:	e9890913          	addi	s2,s2,-360 # 80017428 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002598:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000259a:	00006997          	auipc	s3,0x6
    8000259e:	d6698993          	addi	s3,s3,-666 # 80008300 <digits+0x2c0>
    printf("%d %s %s", p->pid, state, p->name);
    800025a2:	00006a97          	auipc	s5,0x6
    800025a6:	d66a8a93          	addi	s5,s5,-666 # 80008308 <digits+0x2c8>
    printf("\n");
    800025aa:	00006a17          	auipc	s4,0x6
    800025ae:	b1ea0a13          	addi	s4,s4,-1250 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b2:	00006b97          	auipc	s7,0x6
    800025b6:	d8eb8b93          	addi	s7,s7,-626 # 80008340 <states.1734>
    800025ba:	a00d                	j	800025dc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025bc:	ed86a583          	lw	a1,-296(a3)
    800025c0:	8556                	mv	a0,s5
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	fc6080e7          	jalr	-58(ra) # 80000588 <printf>
    printf("\n");
    800025ca:	8552                	mv	a0,s4
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbc080e7          	jalr	-68(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d4:	17048493          	addi	s1,s1,368
    800025d8:	03248163          	beq	s1,s2,800025fa <procdump+0x98>
    if(p->state == UNUSED)
    800025dc:	86a6                	mv	a3,s1
    800025de:	ec04a783          	lw	a5,-320(s1)
    800025e2:	dbed                	beqz	a5,800025d4 <procdump+0x72>
      state = "???";
    800025e4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e6:	fcfb6be3          	bltu	s6,a5,800025bc <procdump+0x5a>
    800025ea:	1782                	slli	a5,a5,0x20
    800025ec:	9381                	srli	a5,a5,0x20
    800025ee:	078e                	slli	a5,a5,0x3
    800025f0:	97de                	add	a5,a5,s7
    800025f2:	6390                	ld	a2,0(a5)
    800025f4:	f661                	bnez	a2,800025bc <procdump+0x5a>
      state = "???";
    800025f6:	864e                	mv	a2,s3
    800025f8:	b7d1                	j	800025bc <procdump+0x5a>
  }
}
    800025fa:	60a6                	ld	ra,72(sp)
    800025fc:	6406                	ld	s0,64(sp)
    800025fe:	74e2                	ld	s1,56(sp)
    80002600:	7942                	ld	s2,48(sp)
    80002602:	79a2                	ld	s3,40(sp)
    80002604:	7a02                	ld	s4,32(sp)
    80002606:	6ae2                	ld	s5,24(sp)
    80002608:	6b42                	ld	s6,16(sp)
    8000260a:	6ba2                	ld	s7,8(sp)
    8000260c:	6161                	addi	sp,sp,80
    8000260e:	8082                	ret

0000000080002610 <swtch>:
    80002610:	00153023          	sd	ra,0(a0)
    80002614:	00253423          	sd	sp,8(a0)
    80002618:	e900                	sd	s0,16(a0)
    8000261a:	ed04                	sd	s1,24(a0)
    8000261c:	03253023          	sd	s2,32(a0)
    80002620:	03353423          	sd	s3,40(a0)
    80002624:	03453823          	sd	s4,48(a0)
    80002628:	03553c23          	sd	s5,56(a0)
    8000262c:	05653023          	sd	s6,64(a0)
    80002630:	05753423          	sd	s7,72(a0)
    80002634:	05853823          	sd	s8,80(a0)
    80002638:	05953c23          	sd	s9,88(a0)
    8000263c:	07a53023          	sd	s10,96(a0)
    80002640:	07b53423          	sd	s11,104(a0)
    80002644:	0005b083          	ld	ra,0(a1)
    80002648:	0085b103          	ld	sp,8(a1)
    8000264c:	6980                	ld	s0,16(a1)
    8000264e:	6d84                	ld	s1,24(a1)
    80002650:	0205b903          	ld	s2,32(a1)
    80002654:	0285b983          	ld	s3,40(a1)
    80002658:	0305ba03          	ld	s4,48(a1)
    8000265c:	0385ba83          	ld	s5,56(a1)
    80002660:	0405bb03          	ld	s6,64(a1)
    80002664:	0485bb83          	ld	s7,72(a1)
    80002668:	0505bc03          	ld	s8,80(a1)
    8000266c:	0585bc83          	ld	s9,88(a1)
    80002670:	0605bd03          	ld	s10,96(a1)
    80002674:	0685bd83          	ld	s11,104(a1)
    80002678:	8082                	ret

000000008000267a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000267a:	1141                	addi	sp,sp,-16
    8000267c:	e406                	sd	ra,8(sp)
    8000267e:	e022                	sd	s0,0(sp)
    80002680:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002682:	00006597          	auipc	a1,0x6
    80002686:	cee58593          	addi	a1,a1,-786 # 80008370 <states.1734+0x30>
    8000268a:	00015517          	auipc	a0,0x15
    8000268e:	c4650513          	addi	a0,a0,-954 # 800172d0 <tickslock>
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	4c2080e7          	jalr	1218(ra) # 80000b54 <initlock>
}
    8000269a:	60a2                	ld	ra,8(sp)
    8000269c:	6402                	ld	s0,0(sp)
    8000269e:	0141                	addi	sp,sp,16
    800026a0:	8082                	ret

00000000800026a2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026a2:	1141                	addi	sp,sp,-16
    800026a4:	e422                	sd	s0,8(sp)
    800026a6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a8:	00003797          	auipc	a5,0x3
    800026ac:	4f878793          	addi	a5,a5,1272 # 80005ba0 <kernelvec>
    800026b0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026b4:	6422                	ld	s0,8(sp)
    800026b6:	0141                	addi	sp,sp,16
    800026b8:	8082                	ret

00000000800026ba <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ba:	1141                	addi	sp,sp,-16
    800026bc:	e406                	sd	ra,8(sp)
    800026be:	e022                	sd	s0,0(sp)
    800026c0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	364080e7          	jalr	868(ra) # 80001a26 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026ce:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026d0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026d4:	00005617          	auipc	a2,0x5
    800026d8:	92c60613          	addi	a2,a2,-1748 # 80007000 <_trampoline>
    800026dc:	00005697          	auipc	a3,0x5
    800026e0:	92468693          	addi	a3,a3,-1756 # 80007000 <_trampoline>
    800026e4:	8e91                	sub	a3,a3,a2
    800026e6:	040007b7          	lui	a5,0x4000
    800026ea:	17fd                	addi	a5,a5,-1
    800026ec:	07b2                	slli	a5,a5,0xc
    800026ee:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026f4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026f6:	180026f3          	csrr	a3,satp
    800026fa:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026fc:	6d38                	ld	a4,88(a0)
    800026fe:	6134                	ld	a3,64(a0)
    80002700:	6585                	lui	a1,0x1
    80002702:	96ae                	add	a3,a3,a1
    80002704:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002706:	6d38                	ld	a4,88(a0)
    80002708:	00000697          	auipc	a3,0x0
    8000270c:	13868693          	addi	a3,a3,312 # 80002840 <usertrap>
    80002710:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002712:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002714:	8692                	mv	a3,tp
    80002716:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002718:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000271c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002720:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002724:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002728:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000272a:	6f18                	ld	a4,24(a4)
    8000272c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002730:	692c                	ld	a1,80(a0)
    80002732:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002734:	00005717          	auipc	a4,0x5
    80002738:	95c70713          	addi	a4,a4,-1700 # 80007090 <userret>
    8000273c:	8f11                	sub	a4,a4,a2
    8000273e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002740:	577d                	li	a4,-1
    80002742:	177e                	slli	a4,a4,0x3f
    80002744:	8dd9                	or	a1,a1,a4
    80002746:	02000537          	lui	a0,0x2000
    8000274a:	157d                	addi	a0,a0,-1
    8000274c:	0536                	slli	a0,a0,0xd
    8000274e:	9782                	jalr	a5
}
    80002750:	60a2                	ld	ra,8(sp)
    80002752:	6402                	ld	s0,0(sp)
    80002754:	0141                	addi	sp,sp,16
    80002756:	8082                	ret

0000000080002758 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002758:	1101                	addi	sp,sp,-32
    8000275a:	ec06                	sd	ra,24(sp)
    8000275c:	e822                	sd	s0,16(sp)
    8000275e:	e426                	sd	s1,8(sp)
    80002760:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002762:	00015497          	auipc	s1,0x15
    80002766:	b6e48493          	addi	s1,s1,-1170 # 800172d0 <tickslock>
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	478080e7          	jalr	1144(ra) # 80000be4 <acquire>
  ticks++;
    80002774:	00007517          	auipc	a0,0x7
    80002778:	8bc50513          	addi	a0,a0,-1860 # 80009030 <ticks>
    8000277c:	411c                	lw	a5,0(a0)
    8000277e:	2785                	addiw	a5,a5,1
    80002780:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002782:	00000097          	auipc	ra,0x0
    80002786:	b1c080e7          	jalr	-1252(ra) # 8000229e <wakeup>
  release(&tickslock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	50c080e7          	jalr	1292(ra) # 80000c98 <release>
}
    80002794:	60e2                	ld	ra,24(sp)
    80002796:	6442                	ld	s0,16(sp)
    80002798:	64a2                	ld	s1,8(sp)
    8000279a:	6105                	addi	sp,sp,32
    8000279c:	8082                	ret

000000008000279e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000279e:	1101                	addi	sp,sp,-32
    800027a0:	ec06                	sd	ra,24(sp)
    800027a2:	e822                	sd	s0,16(sp)
    800027a4:	e426                	sd	s1,8(sp)
    800027a6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027a8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027ac:	00074d63          	bltz	a4,800027c6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027b0:	57fd                	li	a5,-1
    800027b2:	17fe                	slli	a5,a5,0x3f
    800027b4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027b6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027b8:	06f70363          	beq	a4,a5,8000281e <devintr+0x80>
  }
}
    800027bc:	60e2                	ld	ra,24(sp)
    800027be:	6442                	ld	s0,16(sp)
    800027c0:	64a2                	ld	s1,8(sp)
    800027c2:	6105                	addi	sp,sp,32
    800027c4:	8082                	ret
     (scause & 0xff) == 9){
    800027c6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027ca:	46a5                	li	a3,9
    800027cc:	fed792e3          	bne	a5,a3,800027b0 <devintr+0x12>
    int irq = plic_claim();
    800027d0:	00003097          	auipc	ra,0x3
    800027d4:	4d8080e7          	jalr	1240(ra) # 80005ca8 <plic_claim>
    800027d8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027da:	47a9                	li	a5,10
    800027dc:	02f50763          	beq	a0,a5,8000280a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027e0:	4785                	li	a5,1
    800027e2:	02f50963          	beq	a0,a5,80002814 <devintr+0x76>
    return 1;
    800027e6:	4505                	li	a0,1
    } else if(irq){
    800027e8:	d8f1                	beqz	s1,800027bc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027ea:	85a6                	mv	a1,s1
    800027ec:	00006517          	auipc	a0,0x6
    800027f0:	b8c50513          	addi	a0,a0,-1140 # 80008378 <states.1734+0x38>
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	d94080e7          	jalr	-620(ra) # 80000588 <printf>
      plic_complete(irq);
    800027fc:	8526                	mv	a0,s1
    800027fe:	00003097          	auipc	ra,0x3
    80002802:	4ce080e7          	jalr	1230(ra) # 80005ccc <plic_complete>
    return 1;
    80002806:	4505                	li	a0,1
    80002808:	bf55                	j	800027bc <devintr+0x1e>
      uartintr();
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	19e080e7          	jalr	414(ra) # 800009a8 <uartintr>
    80002812:	b7ed                	j	800027fc <devintr+0x5e>
      virtio_disk_intr();
    80002814:	00004097          	auipc	ra,0x4
    80002818:	998080e7          	jalr	-1640(ra) # 800061ac <virtio_disk_intr>
    8000281c:	b7c5                	j	800027fc <devintr+0x5e>
    if(cpuid() == 0){
    8000281e:	fffff097          	auipc	ra,0xfffff
    80002822:	1dc080e7          	jalr	476(ra) # 800019fa <cpuid>
    80002826:	c901                	beqz	a0,80002836 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002828:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000282c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000282e:	14479073          	csrw	sip,a5
    return 2;
    80002832:	4509                	li	a0,2
    80002834:	b761                	j	800027bc <devintr+0x1e>
      clockintr();
    80002836:	00000097          	auipc	ra,0x0
    8000283a:	f22080e7          	jalr	-222(ra) # 80002758 <clockintr>
    8000283e:	b7ed                	j	80002828 <devintr+0x8a>

0000000080002840 <usertrap>:
{
    80002840:	1101                	addi	sp,sp,-32
    80002842:	ec06                	sd	ra,24(sp)
    80002844:	e822                	sd	s0,16(sp)
    80002846:	e426                	sd	s1,8(sp)
    80002848:	e04a                	sd	s2,0(sp)
    8000284a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000284c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002850:	1007f793          	andi	a5,a5,256
    80002854:	e3ad                	bnez	a5,800028b6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002856:	00003797          	auipc	a5,0x3
    8000285a:	34a78793          	addi	a5,a5,842 # 80005ba0 <kernelvec>
    8000285e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	1c4080e7          	jalr	452(ra) # 80001a26 <myproc>
    8000286a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000286c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000286e:	14102773          	csrr	a4,sepc
    80002872:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002874:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002878:	47a1                	li	a5,8
    8000287a:	04f71c63          	bne	a4,a5,800028d2 <usertrap+0x92>
    if(p->killed)
    8000287e:	551c                	lw	a5,40(a0)
    80002880:	e3b9                	bnez	a5,800028c6 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002882:	6cb8                	ld	a4,88(s1)
    80002884:	6f1c                	ld	a5,24(a4)
    80002886:	0791                	addi	a5,a5,4
    80002888:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000288e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002892:	10079073          	csrw	sstatus,a5
    syscall();
    80002896:	00000097          	auipc	ra,0x0
    8000289a:	2e0080e7          	jalr	736(ra) # 80002b76 <syscall>
  if(p->killed)
    8000289e:	549c                	lw	a5,40(s1)
    800028a0:	ebc1                	bnez	a5,80002930 <usertrap+0xf0>
  usertrapret();
    800028a2:	00000097          	auipc	ra,0x0
    800028a6:	e18080e7          	jalr	-488(ra) # 800026ba <usertrapret>
}
    800028aa:	60e2                	ld	ra,24(sp)
    800028ac:	6442                	ld	s0,16(sp)
    800028ae:	64a2                	ld	s1,8(sp)
    800028b0:	6902                	ld	s2,0(sp)
    800028b2:	6105                	addi	sp,sp,32
    800028b4:	8082                	ret
    panic("usertrap: not from user mode");
    800028b6:	00006517          	auipc	a0,0x6
    800028ba:	ae250513          	addi	a0,a0,-1310 # 80008398 <states.1734+0x58>
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	c80080e7          	jalr	-896(ra) # 8000053e <panic>
      exit(-1);
    800028c6:	557d                	li	a0,-1
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	aa6080e7          	jalr	-1370(ra) # 8000236e <exit>
    800028d0:	bf4d                	j	80002882 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	ecc080e7          	jalr	-308(ra) # 8000279e <devintr>
    800028da:	892a                	mv	s2,a0
    800028dc:	c501                	beqz	a0,800028e4 <usertrap+0xa4>
  if(p->killed)
    800028de:	549c                	lw	a5,40(s1)
    800028e0:	c3a1                	beqz	a5,80002920 <usertrap+0xe0>
    800028e2:	a815                	j	80002916 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028e8:	5890                	lw	a2,48(s1)
    800028ea:	00006517          	auipc	a0,0x6
    800028ee:	ace50513          	addi	a0,a0,-1330 # 800083b8 <states.1734+0x78>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	c96080e7          	jalr	-874(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028fe:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002902:	00006517          	auipc	a0,0x6
    80002906:	ae650513          	addi	a0,a0,-1306 # 800083e8 <states.1734+0xa8>
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	c7e080e7          	jalr	-898(ra) # 80000588 <printf>
    p->killed = 1;
    80002912:	4785                	li	a5,1
    80002914:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002916:	557d                	li	a0,-1
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	a56080e7          	jalr	-1450(ra) # 8000236e <exit>
  if(which_dev == 2)
    80002920:	4789                	li	a5,2
    80002922:	f8f910e3          	bne	s2,a5,800028a2 <usertrap+0x62>
    yield();
    80002926:	fffff097          	auipc	ra,0xfffff
    8000292a:	7b0080e7          	jalr	1968(ra) # 800020d6 <yield>
    8000292e:	bf95                	j	800028a2 <usertrap+0x62>
  int which_dev = 0;
    80002930:	4901                	li	s2,0
    80002932:	b7d5                	j	80002916 <usertrap+0xd6>

0000000080002934 <kerneltrap>:
{
    80002934:	7179                	addi	sp,sp,-48
    80002936:	f406                	sd	ra,40(sp)
    80002938:	f022                	sd	s0,32(sp)
    8000293a:	ec26                	sd	s1,24(sp)
    8000293c:	e84a                	sd	s2,16(sp)
    8000293e:	e44e                	sd	s3,8(sp)
    80002940:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002942:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002946:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000294a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000294e:	1004f793          	andi	a5,s1,256
    80002952:	cb85                	beqz	a5,80002982 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002954:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002958:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000295a:	ef85                	bnez	a5,80002992 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000295c:	00000097          	auipc	ra,0x0
    80002960:	e42080e7          	jalr	-446(ra) # 8000279e <devintr>
    80002964:	cd1d                	beqz	a0,800029a2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002966:	4789                	li	a5,2
    80002968:	06f50a63          	beq	a0,a5,800029dc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000296c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002970:	10049073          	csrw	sstatus,s1
}
    80002974:	70a2                	ld	ra,40(sp)
    80002976:	7402                	ld	s0,32(sp)
    80002978:	64e2                	ld	s1,24(sp)
    8000297a:	6942                	ld	s2,16(sp)
    8000297c:	69a2                	ld	s3,8(sp)
    8000297e:	6145                	addi	sp,sp,48
    80002980:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002982:	00006517          	auipc	a0,0x6
    80002986:	a8650513          	addi	a0,a0,-1402 # 80008408 <states.1734+0xc8>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	bb4080e7          	jalr	-1100(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002992:	00006517          	auipc	a0,0x6
    80002996:	a9e50513          	addi	a0,a0,-1378 # 80008430 <states.1734+0xf0>
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	ba4080e7          	jalr	-1116(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800029a2:	85ce                	mv	a1,s3
    800029a4:	00006517          	auipc	a0,0x6
    800029a8:	aac50513          	addi	a0,a0,-1364 # 80008450 <states.1734+0x110>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	bdc080e7          	jalr	-1060(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	aa450513          	addi	a0,a0,-1372 # 80008460 <states.1734+0x120>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	bc4080e7          	jalr	-1084(ra) # 80000588 <printf>
    panic("kerneltrap");
    800029cc:	00006517          	auipc	a0,0x6
    800029d0:	aac50513          	addi	a0,a0,-1364 # 80008478 <states.1734+0x138>
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	b6a080e7          	jalr	-1174(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	04a080e7          	jalr	74(ra) # 80001a26 <myproc>
    800029e4:	d541                	beqz	a0,8000296c <kerneltrap+0x38>
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	040080e7          	jalr	64(ra) # 80001a26 <myproc>
    800029ee:	4d18                	lw	a4,24(a0)
    800029f0:	4791                	li	a5,4
    800029f2:	f6f71de3          	bne	a4,a5,8000296c <kerneltrap+0x38>
    yield();
    800029f6:	fffff097          	auipc	ra,0xfffff
    800029fa:	6e0080e7          	jalr	1760(ra) # 800020d6 <yield>
    800029fe:	b7bd                	j	8000296c <kerneltrap+0x38>

0000000080002a00 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a00:	1101                	addi	sp,sp,-32
    80002a02:	ec06                	sd	ra,24(sp)
    80002a04:	e822                	sd	s0,16(sp)
    80002a06:	e426                	sd	s1,8(sp)
    80002a08:	1000                	addi	s0,sp,32
    80002a0a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a0c:	fffff097          	auipc	ra,0xfffff
    80002a10:	01a080e7          	jalr	26(ra) # 80001a26 <myproc>
  switch (n) {
    80002a14:	4795                	li	a5,5
    80002a16:	0497e163          	bltu	a5,s1,80002a58 <argraw+0x58>
    80002a1a:	048a                	slli	s1,s1,0x2
    80002a1c:	00006717          	auipc	a4,0x6
    80002a20:	a9470713          	addi	a4,a4,-1388 # 800084b0 <states.1734+0x170>
    80002a24:	94ba                	add	s1,s1,a4
    80002a26:	409c                	lw	a5,0(s1)
    80002a28:	97ba                	add	a5,a5,a4
    80002a2a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a2c:	6d3c                	ld	a5,88(a0)
    80002a2e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a30:	60e2                	ld	ra,24(sp)
    80002a32:	6442                	ld	s0,16(sp)
    80002a34:	64a2                	ld	s1,8(sp)
    80002a36:	6105                	addi	sp,sp,32
    80002a38:	8082                	ret
    return p->trapframe->a1;
    80002a3a:	6d3c                	ld	a5,88(a0)
    80002a3c:	7fa8                	ld	a0,120(a5)
    80002a3e:	bfcd                	j	80002a30 <argraw+0x30>
    return p->trapframe->a2;
    80002a40:	6d3c                	ld	a5,88(a0)
    80002a42:	63c8                	ld	a0,128(a5)
    80002a44:	b7f5                	j	80002a30 <argraw+0x30>
    return p->trapframe->a3;
    80002a46:	6d3c                	ld	a5,88(a0)
    80002a48:	67c8                	ld	a0,136(a5)
    80002a4a:	b7dd                	j	80002a30 <argraw+0x30>
    return p->trapframe->a4;
    80002a4c:	6d3c                	ld	a5,88(a0)
    80002a4e:	6bc8                	ld	a0,144(a5)
    80002a50:	b7c5                	j	80002a30 <argraw+0x30>
    return p->trapframe->a5;
    80002a52:	6d3c                	ld	a5,88(a0)
    80002a54:	6fc8                	ld	a0,152(a5)
    80002a56:	bfe9                	j	80002a30 <argraw+0x30>
  panic("argraw");
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	a3050513          	addi	a0,a0,-1488 # 80008488 <states.1734+0x148>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	ade080e7          	jalr	-1314(ra) # 8000053e <panic>

0000000080002a68 <fetchaddr>:
{
    80002a68:	1101                	addi	sp,sp,-32
    80002a6a:	ec06                	sd	ra,24(sp)
    80002a6c:	e822                	sd	s0,16(sp)
    80002a6e:	e426                	sd	s1,8(sp)
    80002a70:	e04a                	sd	s2,0(sp)
    80002a72:	1000                	addi	s0,sp,32
    80002a74:	84aa                	mv	s1,a0
    80002a76:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	fae080e7          	jalr	-82(ra) # 80001a26 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a80:	653c                	ld	a5,72(a0)
    80002a82:	02f4f863          	bgeu	s1,a5,80002ab2 <fetchaddr+0x4a>
    80002a86:	00848713          	addi	a4,s1,8
    80002a8a:	02e7e663          	bltu	a5,a4,80002ab6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a8e:	46a1                	li	a3,8
    80002a90:	8626                	mv	a2,s1
    80002a92:	85ca                	mv	a1,s2
    80002a94:	6928                	ld	a0,80(a0)
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	c68080e7          	jalr	-920(ra) # 800016fe <copyin>
    80002a9e:	00a03533          	snez	a0,a0
    80002aa2:	40a00533          	neg	a0,a0
}
    80002aa6:	60e2                	ld	ra,24(sp)
    80002aa8:	6442                	ld	s0,16(sp)
    80002aaa:	64a2                	ld	s1,8(sp)
    80002aac:	6902                	ld	s2,0(sp)
    80002aae:	6105                	addi	sp,sp,32
    80002ab0:	8082                	ret
    return -1;
    80002ab2:	557d                	li	a0,-1
    80002ab4:	bfcd                	j	80002aa6 <fetchaddr+0x3e>
    80002ab6:	557d                	li	a0,-1
    80002ab8:	b7fd                	j	80002aa6 <fetchaddr+0x3e>

0000000080002aba <fetchstr>:
{
    80002aba:	7179                	addi	sp,sp,-48
    80002abc:	f406                	sd	ra,40(sp)
    80002abe:	f022                	sd	s0,32(sp)
    80002ac0:	ec26                	sd	s1,24(sp)
    80002ac2:	e84a                	sd	s2,16(sp)
    80002ac4:	e44e                	sd	s3,8(sp)
    80002ac6:	1800                	addi	s0,sp,48
    80002ac8:	892a                	mv	s2,a0
    80002aca:	84ae                	mv	s1,a1
    80002acc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	f58080e7          	jalr	-168(ra) # 80001a26 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ad6:	86ce                	mv	a3,s3
    80002ad8:	864a                	mv	a2,s2
    80002ada:	85a6                	mv	a1,s1
    80002adc:	6928                	ld	a0,80(a0)
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	cac080e7          	jalr	-852(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002ae6:	00054763          	bltz	a0,80002af4 <fetchstr+0x3a>
  return strlen(buf);
    80002aea:	8526                	mv	a0,s1
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	378080e7          	jalr	888(ra) # 80000e64 <strlen>
}
    80002af4:	70a2                	ld	ra,40(sp)
    80002af6:	7402                	ld	s0,32(sp)
    80002af8:	64e2                	ld	s1,24(sp)
    80002afa:	6942                	ld	s2,16(sp)
    80002afc:	69a2                	ld	s3,8(sp)
    80002afe:	6145                	addi	sp,sp,48
    80002b00:	8082                	ret

0000000080002b02 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b02:	1101                	addi	sp,sp,-32
    80002b04:	ec06                	sd	ra,24(sp)
    80002b06:	e822                	sd	s0,16(sp)
    80002b08:	e426                	sd	s1,8(sp)
    80002b0a:	1000                	addi	s0,sp,32
    80002b0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	ef2080e7          	jalr	-270(ra) # 80002a00 <argraw>
    80002b16:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b18:	4501                	li	a0,0
    80002b1a:	60e2                	ld	ra,24(sp)
    80002b1c:	6442                	ld	s0,16(sp)
    80002b1e:	64a2                	ld	s1,8(sp)
    80002b20:	6105                	addi	sp,sp,32
    80002b22:	8082                	ret

0000000080002b24 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b24:	1101                	addi	sp,sp,-32
    80002b26:	ec06                	sd	ra,24(sp)
    80002b28:	e822                	sd	s0,16(sp)
    80002b2a:	e426                	sd	s1,8(sp)
    80002b2c:	1000                	addi	s0,sp,32
    80002b2e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b30:	00000097          	auipc	ra,0x0
    80002b34:	ed0080e7          	jalr	-304(ra) # 80002a00 <argraw>
    80002b38:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b3a:	4501                	li	a0,0
    80002b3c:	60e2                	ld	ra,24(sp)
    80002b3e:	6442                	ld	s0,16(sp)
    80002b40:	64a2                	ld	s1,8(sp)
    80002b42:	6105                	addi	sp,sp,32
    80002b44:	8082                	ret

0000000080002b46 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b46:	1101                	addi	sp,sp,-32
    80002b48:	ec06                	sd	ra,24(sp)
    80002b4a:	e822                	sd	s0,16(sp)
    80002b4c:	e426                	sd	s1,8(sp)
    80002b4e:	e04a                	sd	s2,0(sp)
    80002b50:	1000                	addi	s0,sp,32
    80002b52:	84ae                	mv	s1,a1
    80002b54:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b56:	00000097          	auipc	ra,0x0
    80002b5a:	eaa080e7          	jalr	-342(ra) # 80002a00 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b5e:	864a                	mv	a2,s2
    80002b60:	85a6                	mv	a1,s1
    80002b62:	00000097          	auipc	ra,0x0
    80002b66:	f58080e7          	jalr	-168(ra) # 80002aba <fetchstr>
}
    80002b6a:	60e2                	ld	ra,24(sp)
    80002b6c:	6442                	ld	s0,16(sp)
    80002b6e:	64a2                	ld	s1,8(sp)
    80002b70:	6902                	ld	s2,0(sp)
    80002b72:	6105                	addi	sp,sp,32
    80002b74:	8082                	ret

0000000080002b76 <syscall>:
[SYS_info]    sys_info,
};

void
syscall(void)
{
    80002b76:	1101                	addi	sp,sp,-32
    80002b78:	ec06                	sd	ra,24(sp)
    80002b7a:	e822                	sd	s0,16(sp)
    80002b7c:	e426                	sd	s1,8(sp)
    80002b7e:	e04a                	sd	s2,0(sp)
    80002b80:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b82:	fffff097          	auipc	ra,0xfffff
    80002b86:	ea4080e7          	jalr	-348(ra) # 80001a26 <myproc>
    80002b8a:	84aa                	mv	s1,a0
  p->syscallCount++;
    80002b8c:	16853783          	ld	a5,360(a0)
    80002b90:	0785                	addi	a5,a5,1
    80002b92:	16f53423          	sd	a5,360(a0)

  num = p->trapframe->a7;
    80002b96:	05853903          	ld	s2,88(a0)
    80002b9a:	0a893783          	ld	a5,168(s2)
    80002b9e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ba2:	37fd                	addiw	a5,a5,-1
    80002ba4:	4755                	li	a4,21
    80002ba6:	00f76f63          	bltu	a4,a5,80002bc4 <syscall+0x4e>
    80002baa:	00369713          	slli	a4,a3,0x3
    80002bae:	00006797          	auipc	a5,0x6
    80002bb2:	91a78793          	addi	a5,a5,-1766 # 800084c8 <syscalls>
    80002bb6:	97ba                	add	a5,a5,a4
    80002bb8:	639c                	ld	a5,0(a5)
    80002bba:	c789                	beqz	a5,80002bc4 <syscall+0x4e>
    p->trapframe->a0 = syscalls[num]();
    80002bbc:	9782                	jalr	a5
    80002bbe:	06a93823          	sd	a0,112(s2)
    80002bc2:	a839                	j	80002be0 <syscall+0x6a>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bc4:	15848613          	addi	a2,s1,344
    80002bc8:	588c                	lw	a1,48(s1)
    80002bca:	00006517          	auipc	a0,0x6
    80002bce:	8c650513          	addi	a0,a0,-1850 # 80008490 <states.1734+0x150>
    80002bd2:	ffffe097          	auipc	ra,0xffffe
    80002bd6:	9b6080e7          	jalr	-1610(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bda:	6cbc                	ld	a5,88(s1)
    80002bdc:	577d                	li	a4,-1
    80002bde:	fbb8                	sd	a4,112(a5)
  }
}
    80002be0:	60e2                	ld	ra,24(sp)
    80002be2:	6442                	ld	s0,16(sp)
    80002be4:	64a2                	ld	s1,8(sp)
    80002be6:	6902                	ld	s2,0(sp)
    80002be8:	6105                	addi	sp,sp,32
    80002bea:	8082                	ret

0000000080002bec <sys_info>:
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64 sys_info(void){
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	1000                	addi	s0,sp,32
	int n;
	argint(0,&n);
    80002bf4:	fec40593          	addi	a1,s0,-20
    80002bf8:	4501                	li	a0,0
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	f08080e7          	jalr	-248(ra) # 80002b02 <argint>
	printf("The value of n is %d\n", n);
    80002c02:	fec42583          	lw	a1,-20(s0)
    80002c06:	00006517          	auipc	a0,0x6
    80002c0a:	97a50513          	addi	a0,a0,-1670 # 80008580 <syscalls+0xb8>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	97a080e7          	jalr	-1670(ra) # 80000588 <printf>
	if (n == 1){
    80002c16:	fec42783          	lw	a5,-20(s0)
    80002c1a:	4705                	li	a4,1
    80002c1c:	00e78d63          	beq	a5,a4,80002c36 <sys_info+0x4a>
		process_count_print();
	}
	else if (n == 2){
    80002c20:	4709                	li	a4,2
    80002c22:	00e78f63          	beq	a5,a4,80002c40 <sys_info+0x54>
		syscall_count_print();
	}
  else if (n == 3){
    80002c26:	470d                	li	a4,3
    80002c28:	02e78163          	beq	a5,a4,80002c4a <sys_info+0x5e>
    mem_pages_count_print();
  }
	return 0;
}
    80002c2c:	4501                	li	a0,0
    80002c2e:	60e2                	ld	ra,24(sp)
    80002c30:	6442                	ld	s0,16(sp)
    80002c32:	6105                	addi	sp,sp,32
    80002c34:	8082                	ret
		process_count_print();
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	c9e080e7          	jalr	-866(ra) # 800018d4 <process_count_print>
    80002c3e:	b7fd                	j	80002c2c <sys_info+0x40>
		syscall_count_print();
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	e1e080e7          	jalr	-482(ra) # 80001a5e <syscall_count_print>
    80002c48:	b7d5                	j	80002c2c <sys_info+0x40>
    mem_pages_count_print();
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	cce080e7          	jalr	-818(ra) # 80001918 <mem_pages_count_print>
    80002c52:	bfe9                	j	80002c2c <sys_info+0x40>

0000000080002c54 <sys_exit>:

uint64
sys_exit(void)
{
    80002c54:	1101                	addi	sp,sp,-32
    80002c56:	ec06                	sd	ra,24(sp)
    80002c58:	e822                	sd	s0,16(sp)
    80002c5a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c5c:	fec40593          	addi	a1,s0,-20
    80002c60:	4501                	li	a0,0
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	ea0080e7          	jalr	-352(ra) # 80002b02 <argint>
    return -1;
    80002c6a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c6c:	00054963          	bltz	a0,80002c7e <sys_exit+0x2a>
  exit(n);
    80002c70:	fec42503          	lw	a0,-20(s0)
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	6fa080e7          	jalr	1786(ra) # 8000236e <exit>
  return 0;  // not reached
    80002c7c:	4781                	li	a5,0
}
    80002c7e:	853e                	mv	a0,a5
    80002c80:	60e2                	ld	ra,24(sp)
    80002c82:	6442                	ld	s0,16(sp)
    80002c84:	6105                	addi	sp,sp,32
    80002c86:	8082                	ret

0000000080002c88 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c88:	1141                	addi	sp,sp,-16
    80002c8a:	e406                	sd	ra,8(sp)
    80002c8c:	e022                	sd	s0,0(sp)
    80002c8e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	d96080e7          	jalr	-618(ra) # 80001a26 <myproc>
}
    80002c98:	5908                	lw	a0,48(a0)
    80002c9a:	60a2                	ld	ra,8(sp)
    80002c9c:	6402                	ld	s0,0(sp)
    80002c9e:	0141                	addi	sp,sp,16
    80002ca0:	8082                	ret

0000000080002ca2 <sys_fork>:

uint64
sys_fork(void)
{
    80002ca2:	1141                	addi	sp,sp,-16
    80002ca4:	e406                	sd	ra,8(sp)
    80002ca6:	e022                	sd	s0,0(sp)
    80002ca8:	0800                	addi	s0,sp,16
  return fork();
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	17a080e7          	jalr	378(ra) # 80001e24 <fork>
}
    80002cb2:	60a2                	ld	ra,8(sp)
    80002cb4:	6402                	ld	s0,0(sp)
    80002cb6:	0141                	addi	sp,sp,16
    80002cb8:	8082                	ret

0000000080002cba <sys_wait>:

uint64
sys_wait(void)
{
    80002cba:	1101                	addi	sp,sp,-32
    80002cbc:	ec06                	sd	ra,24(sp)
    80002cbe:	e822                	sd	s0,16(sp)
    80002cc0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cc2:	fe840593          	addi	a1,s0,-24
    80002cc6:	4501                	li	a0,0
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	e5c080e7          	jalr	-420(ra) # 80002b24 <argaddr>
    80002cd0:	87aa                	mv	a5,a0
    return -1;
    80002cd2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cd4:	0007c863          	bltz	a5,80002ce4 <sys_wait+0x2a>
  return wait(p);
    80002cd8:	fe843503          	ld	a0,-24(s0)
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	49a080e7          	jalr	1178(ra) # 80002176 <wait>
}
    80002ce4:	60e2                	ld	ra,24(sp)
    80002ce6:	6442                	ld	s0,16(sp)
    80002ce8:	6105                	addi	sp,sp,32
    80002cea:	8082                	ret

0000000080002cec <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cec:	7179                	addi	sp,sp,-48
    80002cee:	f406                	sd	ra,40(sp)
    80002cf0:	f022                	sd	s0,32(sp)
    80002cf2:	ec26                	sd	s1,24(sp)
    80002cf4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cf6:	fdc40593          	addi	a1,s0,-36
    80002cfa:	4501                	li	a0,0
    80002cfc:	00000097          	auipc	ra,0x0
    80002d00:	e06080e7          	jalr	-506(ra) # 80002b02 <argint>
    80002d04:	87aa                	mv	a5,a0
    return -1;
    80002d06:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d08:	0207c063          	bltz	a5,80002d28 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	d1a080e7          	jalr	-742(ra) # 80001a26 <myproc>
    80002d14:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d16:	fdc42503          	lw	a0,-36(s0)
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	096080e7          	jalr	150(ra) # 80001db0 <growproc>
    80002d22:	00054863          	bltz	a0,80002d32 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d26:	8526                	mv	a0,s1
}
    80002d28:	70a2                	ld	ra,40(sp)
    80002d2a:	7402                	ld	s0,32(sp)
    80002d2c:	64e2                	ld	s1,24(sp)
    80002d2e:	6145                	addi	sp,sp,48
    80002d30:	8082                	ret
    return -1;
    80002d32:	557d                	li	a0,-1
    80002d34:	bfd5                	j	80002d28 <sys_sbrk+0x3c>

0000000080002d36 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d36:	7139                	addi	sp,sp,-64
    80002d38:	fc06                	sd	ra,56(sp)
    80002d3a:	f822                	sd	s0,48(sp)
    80002d3c:	f426                	sd	s1,40(sp)
    80002d3e:	f04a                	sd	s2,32(sp)
    80002d40:	ec4e                	sd	s3,24(sp)
    80002d42:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d44:	fcc40593          	addi	a1,s0,-52
    80002d48:	4501                	li	a0,0
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	db8080e7          	jalr	-584(ra) # 80002b02 <argint>
    return -1;
    80002d52:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d54:	06054563          	bltz	a0,80002dbe <sys_sleep+0x88>
  acquire(&tickslock);
    80002d58:	00014517          	auipc	a0,0x14
    80002d5c:	57850513          	addi	a0,a0,1400 # 800172d0 <tickslock>
    80002d60:	ffffe097          	auipc	ra,0xffffe
    80002d64:	e84080e7          	jalr	-380(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d68:	00006917          	auipc	s2,0x6
    80002d6c:	2c892903          	lw	s2,712(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d70:	fcc42783          	lw	a5,-52(s0)
    80002d74:	cf85                	beqz	a5,80002dac <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d76:	00014997          	auipc	s3,0x14
    80002d7a:	55a98993          	addi	s3,s3,1370 # 800172d0 <tickslock>
    80002d7e:	00006497          	auipc	s1,0x6
    80002d82:	2b248493          	addi	s1,s1,690 # 80009030 <ticks>
    if(myproc()->killed){
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	ca0080e7          	jalr	-864(ra) # 80001a26 <myproc>
    80002d8e:	551c                	lw	a5,40(a0)
    80002d90:	ef9d                	bnez	a5,80002dce <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d92:	85ce                	mv	a1,s3
    80002d94:	8526                	mv	a0,s1
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	37c080e7          	jalr	892(ra) # 80002112 <sleep>
  while(ticks - ticks0 < n){
    80002d9e:	409c                	lw	a5,0(s1)
    80002da0:	412787bb          	subw	a5,a5,s2
    80002da4:	fcc42703          	lw	a4,-52(s0)
    80002da8:	fce7efe3          	bltu	a5,a4,80002d86 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dac:	00014517          	auipc	a0,0x14
    80002db0:	52450513          	addi	a0,a0,1316 # 800172d0 <tickslock>
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	ee4080e7          	jalr	-284(ra) # 80000c98 <release>
  return 0;
    80002dbc:	4781                	li	a5,0
}
    80002dbe:	853e                	mv	a0,a5
    80002dc0:	70e2                	ld	ra,56(sp)
    80002dc2:	7442                	ld	s0,48(sp)
    80002dc4:	74a2                	ld	s1,40(sp)
    80002dc6:	7902                	ld	s2,32(sp)
    80002dc8:	69e2                	ld	s3,24(sp)
    80002dca:	6121                	addi	sp,sp,64
    80002dcc:	8082                	ret
      release(&tickslock);
    80002dce:	00014517          	auipc	a0,0x14
    80002dd2:	50250513          	addi	a0,a0,1282 # 800172d0 <tickslock>
    80002dd6:	ffffe097          	auipc	ra,0xffffe
    80002dda:	ec2080e7          	jalr	-318(ra) # 80000c98 <release>
      return -1;
    80002dde:	57fd                	li	a5,-1
    80002de0:	bff9                	j	80002dbe <sys_sleep+0x88>

0000000080002de2 <sys_kill>:

uint64
sys_kill(void)
{
    80002de2:	1101                	addi	sp,sp,-32
    80002de4:	ec06                	sd	ra,24(sp)
    80002de6:	e822                	sd	s0,16(sp)
    80002de8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dea:	fec40593          	addi	a1,s0,-20
    80002dee:	4501                	li	a0,0
    80002df0:	00000097          	auipc	ra,0x0
    80002df4:	d12080e7          	jalr	-750(ra) # 80002b02 <argint>
    80002df8:	87aa                	mv	a5,a0
    return -1;
    80002dfa:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dfc:	0007c863          	bltz	a5,80002e0c <sys_kill+0x2a>
  return kill(pid);
    80002e00:	fec42503          	lw	a0,-20(s0)
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	640080e7          	jalr	1600(ra) # 80002444 <kill>
}
    80002e0c:	60e2                	ld	ra,24(sp)
    80002e0e:	6442                	ld	s0,16(sp)
    80002e10:	6105                	addi	sp,sp,32
    80002e12:	8082                	ret

0000000080002e14 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e14:	1101                	addi	sp,sp,-32
    80002e16:	ec06                	sd	ra,24(sp)
    80002e18:	e822                	sd	s0,16(sp)
    80002e1a:	e426                	sd	s1,8(sp)
    80002e1c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e1e:	00014517          	auipc	a0,0x14
    80002e22:	4b250513          	addi	a0,a0,1202 # 800172d0 <tickslock>
    80002e26:	ffffe097          	auipc	ra,0xffffe
    80002e2a:	dbe080e7          	jalr	-578(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e2e:	00006497          	auipc	s1,0x6
    80002e32:	2024a483          	lw	s1,514(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e36:	00014517          	auipc	a0,0x14
    80002e3a:	49a50513          	addi	a0,a0,1178 # 800172d0 <tickslock>
    80002e3e:	ffffe097          	auipc	ra,0xffffe
    80002e42:	e5a080e7          	jalr	-422(ra) # 80000c98 <release>
  return xticks;
}
    80002e46:	02049513          	slli	a0,s1,0x20
    80002e4a:	9101                	srli	a0,a0,0x20
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	64a2                	ld	s1,8(sp)
    80002e52:	6105                	addi	sp,sp,32
    80002e54:	8082                	ret

0000000080002e56 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e56:	7179                	addi	sp,sp,-48
    80002e58:	f406                	sd	ra,40(sp)
    80002e5a:	f022                	sd	s0,32(sp)
    80002e5c:	ec26                	sd	s1,24(sp)
    80002e5e:	e84a                	sd	s2,16(sp)
    80002e60:	e44e                	sd	s3,8(sp)
    80002e62:	e052                	sd	s4,0(sp)
    80002e64:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e66:	00005597          	auipc	a1,0x5
    80002e6a:	73258593          	addi	a1,a1,1842 # 80008598 <syscalls+0xd0>
    80002e6e:	00014517          	auipc	a0,0x14
    80002e72:	47a50513          	addi	a0,a0,1146 # 800172e8 <bcache>
    80002e76:	ffffe097          	auipc	ra,0xffffe
    80002e7a:	cde080e7          	jalr	-802(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e7e:	0001c797          	auipc	a5,0x1c
    80002e82:	46a78793          	addi	a5,a5,1130 # 8001f2e8 <bcache+0x8000>
    80002e86:	0001c717          	auipc	a4,0x1c
    80002e8a:	6ca70713          	addi	a4,a4,1738 # 8001f550 <bcache+0x8268>
    80002e8e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e92:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e96:	00014497          	auipc	s1,0x14
    80002e9a:	46a48493          	addi	s1,s1,1130 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002e9e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ea0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ea2:	00005a17          	auipc	s4,0x5
    80002ea6:	6fea0a13          	addi	s4,s4,1790 # 800085a0 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002eaa:	2b893783          	ld	a5,696(s2)
    80002eae:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eb0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002eb4:	85d2                	mv	a1,s4
    80002eb6:	01048513          	addi	a0,s1,16
    80002eba:	00001097          	auipc	ra,0x1
    80002ebe:	4bc080e7          	jalr	1212(ra) # 80004376 <initsleeplock>
    bcache.head.next->prev = b;
    80002ec2:	2b893783          	ld	a5,696(s2)
    80002ec6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ec8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ecc:	45848493          	addi	s1,s1,1112
    80002ed0:	fd349de3          	bne	s1,s3,80002eaa <binit+0x54>
  }
}
    80002ed4:	70a2                	ld	ra,40(sp)
    80002ed6:	7402                	ld	s0,32(sp)
    80002ed8:	64e2                	ld	s1,24(sp)
    80002eda:	6942                	ld	s2,16(sp)
    80002edc:	69a2                	ld	s3,8(sp)
    80002ede:	6a02                	ld	s4,0(sp)
    80002ee0:	6145                	addi	sp,sp,48
    80002ee2:	8082                	ret

0000000080002ee4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ee4:	7179                	addi	sp,sp,-48
    80002ee6:	f406                	sd	ra,40(sp)
    80002ee8:	f022                	sd	s0,32(sp)
    80002eea:	ec26                	sd	s1,24(sp)
    80002eec:	e84a                	sd	s2,16(sp)
    80002eee:	e44e                	sd	s3,8(sp)
    80002ef0:	1800                	addi	s0,sp,48
    80002ef2:	89aa                	mv	s3,a0
    80002ef4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002ef6:	00014517          	auipc	a0,0x14
    80002efa:	3f250513          	addi	a0,a0,1010 # 800172e8 <bcache>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	ce6080e7          	jalr	-794(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f06:	0001c497          	auipc	s1,0x1c
    80002f0a:	69a4b483          	ld	s1,1690(s1) # 8001f5a0 <bcache+0x82b8>
    80002f0e:	0001c797          	auipc	a5,0x1c
    80002f12:	64278793          	addi	a5,a5,1602 # 8001f550 <bcache+0x8268>
    80002f16:	02f48f63          	beq	s1,a5,80002f54 <bread+0x70>
    80002f1a:	873e                	mv	a4,a5
    80002f1c:	a021                	j	80002f24 <bread+0x40>
    80002f1e:	68a4                	ld	s1,80(s1)
    80002f20:	02e48a63          	beq	s1,a4,80002f54 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f24:	449c                	lw	a5,8(s1)
    80002f26:	ff379ce3          	bne	a5,s3,80002f1e <bread+0x3a>
    80002f2a:	44dc                	lw	a5,12(s1)
    80002f2c:	ff2799e3          	bne	a5,s2,80002f1e <bread+0x3a>
      b->refcnt++;
    80002f30:	40bc                	lw	a5,64(s1)
    80002f32:	2785                	addiw	a5,a5,1
    80002f34:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f36:	00014517          	auipc	a0,0x14
    80002f3a:	3b250513          	addi	a0,a0,946 # 800172e8 <bcache>
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	d5a080e7          	jalr	-678(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f46:	01048513          	addi	a0,s1,16
    80002f4a:	00001097          	auipc	ra,0x1
    80002f4e:	466080e7          	jalr	1126(ra) # 800043b0 <acquiresleep>
      return b;
    80002f52:	a8b9                	j	80002fb0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f54:	0001c497          	auipc	s1,0x1c
    80002f58:	6444b483          	ld	s1,1604(s1) # 8001f598 <bcache+0x82b0>
    80002f5c:	0001c797          	auipc	a5,0x1c
    80002f60:	5f478793          	addi	a5,a5,1524 # 8001f550 <bcache+0x8268>
    80002f64:	00f48863          	beq	s1,a5,80002f74 <bread+0x90>
    80002f68:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f6a:	40bc                	lw	a5,64(s1)
    80002f6c:	cf81                	beqz	a5,80002f84 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f6e:	64a4                	ld	s1,72(s1)
    80002f70:	fee49de3          	bne	s1,a4,80002f6a <bread+0x86>
  panic("bget: no buffers");
    80002f74:	00005517          	auipc	a0,0x5
    80002f78:	63450513          	addi	a0,a0,1588 # 800085a8 <syscalls+0xe0>
    80002f7c:	ffffd097          	auipc	ra,0xffffd
    80002f80:	5c2080e7          	jalr	1474(ra) # 8000053e <panic>
      b->dev = dev;
    80002f84:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f88:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f8c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f90:	4785                	li	a5,1
    80002f92:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f94:	00014517          	auipc	a0,0x14
    80002f98:	35450513          	addi	a0,a0,852 # 800172e8 <bcache>
    80002f9c:	ffffe097          	auipc	ra,0xffffe
    80002fa0:	cfc080e7          	jalr	-772(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002fa4:	01048513          	addi	a0,s1,16
    80002fa8:	00001097          	auipc	ra,0x1
    80002fac:	408080e7          	jalr	1032(ra) # 800043b0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fb0:	409c                	lw	a5,0(s1)
    80002fb2:	cb89                	beqz	a5,80002fc4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fb4:	8526                	mv	a0,s1
    80002fb6:	70a2                	ld	ra,40(sp)
    80002fb8:	7402                	ld	s0,32(sp)
    80002fba:	64e2                	ld	s1,24(sp)
    80002fbc:	6942                	ld	s2,16(sp)
    80002fbe:	69a2                	ld	s3,8(sp)
    80002fc0:	6145                	addi	sp,sp,48
    80002fc2:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fc4:	4581                	li	a1,0
    80002fc6:	8526                	mv	a0,s1
    80002fc8:	00003097          	auipc	ra,0x3
    80002fcc:	f0e080e7          	jalr	-242(ra) # 80005ed6 <virtio_disk_rw>
    b->valid = 1;
    80002fd0:	4785                	li	a5,1
    80002fd2:	c09c                	sw	a5,0(s1)
  return b;
    80002fd4:	b7c5                	j	80002fb4 <bread+0xd0>

0000000080002fd6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	e426                	sd	s1,8(sp)
    80002fde:	1000                	addi	s0,sp,32
    80002fe0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fe2:	0541                	addi	a0,a0,16
    80002fe4:	00001097          	auipc	ra,0x1
    80002fe8:	466080e7          	jalr	1126(ra) # 8000444a <holdingsleep>
    80002fec:	cd01                	beqz	a0,80003004 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fee:	4585                	li	a1,1
    80002ff0:	8526                	mv	a0,s1
    80002ff2:	00003097          	auipc	ra,0x3
    80002ff6:	ee4080e7          	jalr	-284(ra) # 80005ed6 <virtio_disk_rw>
}
    80002ffa:	60e2                	ld	ra,24(sp)
    80002ffc:	6442                	ld	s0,16(sp)
    80002ffe:	64a2                	ld	s1,8(sp)
    80003000:	6105                	addi	sp,sp,32
    80003002:	8082                	ret
    panic("bwrite");
    80003004:	00005517          	auipc	a0,0x5
    80003008:	5bc50513          	addi	a0,a0,1468 # 800085c0 <syscalls+0xf8>
    8000300c:	ffffd097          	auipc	ra,0xffffd
    80003010:	532080e7          	jalr	1330(ra) # 8000053e <panic>

0000000080003014 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003014:	1101                	addi	sp,sp,-32
    80003016:	ec06                	sd	ra,24(sp)
    80003018:	e822                	sd	s0,16(sp)
    8000301a:	e426                	sd	s1,8(sp)
    8000301c:	e04a                	sd	s2,0(sp)
    8000301e:	1000                	addi	s0,sp,32
    80003020:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003022:	01050913          	addi	s2,a0,16
    80003026:	854a                	mv	a0,s2
    80003028:	00001097          	auipc	ra,0x1
    8000302c:	422080e7          	jalr	1058(ra) # 8000444a <holdingsleep>
    80003030:	c92d                	beqz	a0,800030a2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003032:	854a                	mv	a0,s2
    80003034:	00001097          	auipc	ra,0x1
    80003038:	3d2080e7          	jalr	978(ra) # 80004406 <releasesleep>

  acquire(&bcache.lock);
    8000303c:	00014517          	auipc	a0,0x14
    80003040:	2ac50513          	addi	a0,a0,684 # 800172e8 <bcache>
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	ba0080e7          	jalr	-1120(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000304c:	40bc                	lw	a5,64(s1)
    8000304e:	37fd                	addiw	a5,a5,-1
    80003050:	0007871b          	sext.w	a4,a5
    80003054:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003056:	eb05                	bnez	a4,80003086 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003058:	68bc                	ld	a5,80(s1)
    8000305a:	64b8                	ld	a4,72(s1)
    8000305c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000305e:	64bc                	ld	a5,72(s1)
    80003060:	68b8                	ld	a4,80(s1)
    80003062:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003064:	0001c797          	auipc	a5,0x1c
    80003068:	28478793          	addi	a5,a5,644 # 8001f2e8 <bcache+0x8000>
    8000306c:	2b87b703          	ld	a4,696(a5)
    80003070:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003072:	0001c717          	auipc	a4,0x1c
    80003076:	4de70713          	addi	a4,a4,1246 # 8001f550 <bcache+0x8268>
    8000307a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000307c:	2b87b703          	ld	a4,696(a5)
    80003080:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003082:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003086:	00014517          	auipc	a0,0x14
    8000308a:	26250513          	addi	a0,a0,610 # 800172e8 <bcache>
    8000308e:	ffffe097          	auipc	ra,0xffffe
    80003092:	c0a080e7          	jalr	-1014(ra) # 80000c98 <release>
}
    80003096:	60e2                	ld	ra,24(sp)
    80003098:	6442                	ld	s0,16(sp)
    8000309a:	64a2                	ld	s1,8(sp)
    8000309c:	6902                	ld	s2,0(sp)
    8000309e:	6105                	addi	sp,sp,32
    800030a0:	8082                	ret
    panic("brelse");
    800030a2:	00005517          	auipc	a0,0x5
    800030a6:	52650513          	addi	a0,a0,1318 # 800085c8 <syscalls+0x100>
    800030aa:	ffffd097          	auipc	ra,0xffffd
    800030ae:	494080e7          	jalr	1172(ra) # 8000053e <panic>

00000000800030b2 <bpin>:

void
bpin(struct buf *b) {
    800030b2:	1101                	addi	sp,sp,-32
    800030b4:	ec06                	sd	ra,24(sp)
    800030b6:	e822                	sd	s0,16(sp)
    800030b8:	e426                	sd	s1,8(sp)
    800030ba:	1000                	addi	s0,sp,32
    800030bc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030be:	00014517          	auipc	a0,0x14
    800030c2:	22a50513          	addi	a0,a0,554 # 800172e8 <bcache>
    800030c6:	ffffe097          	auipc	ra,0xffffe
    800030ca:	b1e080e7          	jalr	-1250(ra) # 80000be4 <acquire>
  b->refcnt++;
    800030ce:	40bc                	lw	a5,64(s1)
    800030d0:	2785                	addiw	a5,a5,1
    800030d2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030d4:	00014517          	auipc	a0,0x14
    800030d8:	21450513          	addi	a0,a0,532 # 800172e8 <bcache>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	bbc080e7          	jalr	-1092(ra) # 80000c98 <release>
}
    800030e4:	60e2                	ld	ra,24(sp)
    800030e6:	6442                	ld	s0,16(sp)
    800030e8:	64a2                	ld	s1,8(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret

00000000800030ee <bunpin>:

void
bunpin(struct buf *b) {
    800030ee:	1101                	addi	sp,sp,-32
    800030f0:	ec06                	sd	ra,24(sp)
    800030f2:	e822                	sd	s0,16(sp)
    800030f4:	e426                	sd	s1,8(sp)
    800030f6:	1000                	addi	s0,sp,32
    800030f8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030fa:	00014517          	auipc	a0,0x14
    800030fe:	1ee50513          	addi	a0,a0,494 # 800172e8 <bcache>
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	ae2080e7          	jalr	-1310(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000310a:	40bc                	lw	a5,64(s1)
    8000310c:	37fd                	addiw	a5,a5,-1
    8000310e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003110:	00014517          	auipc	a0,0x14
    80003114:	1d850513          	addi	a0,a0,472 # 800172e8 <bcache>
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	b80080e7          	jalr	-1152(ra) # 80000c98 <release>
}
    80003120:	60e2                	ld	ra,24(sp)
    80003122:	6442                	ld	s0,16(sp)
    80003124:	64a2                	ld	s1,8(sp)
    80003126:	6105                	addi	sp,sp,32
    80003128:	8082                	ret

000000008000312a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000312a:	1101                	addi	sp,sp,-32
    8000312c:	ec06                	sd	ra,24(sp)
    8000312e:	e822                	sd	s0,16(sp)
    80003130:	e426                	sd	s1,8(sp)
    80003132:	e04a                	sd	s2,0(sp)
    80003134:	1000                	addi	s0,sp,32
    80003136:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003138:	00d5d59b          	srliw	a1,a1,0xd
    8000313c:	0001d797          	auipc	a5,0x1d
    80003140:	8887a783          	lw	a5,-1912(a5) # 8001f9c4 <sb+0x1c>
    80003144:	9dbd                	addw	a1,a1,a5
    80003146:	00000097          	auipc	ra,0x0
    8000314a:	d9e080e7          	jalr	-610(ra) # 80002ee4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000314e:	0074f713          	andi	a4,s1,7
    80003152:	4785                	li	a5,1
    80003154:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003158:	14ce                	slli	s1,s1,0x33
    8000315a:	90d9                	srli	s1,s1,0x36
    8000315c:	00950733          	add	a4,a0,s1
    80003160:	05874703          	lbu	a4,88(a4)
    80003164:	00e7f6b3          	and	a3,a5,a4
    80003168:	c69d                	beqz	a3,80003196 <bfree+0x6c>
    8000316a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000316c:	94aa                	add	s1,s1,a0
    8000316e:	fff7c793          	not	a5,a5
    80003172:	8ff9                	and	a5,a5,a4
    80003174:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003178:	00001097          	auipc	ra,0x1
    8000317c:	118080e7          	jalr	280(ra) # 80004290 <log_write>
  brelse(bp);
    80003180:	854a                	mv	a0,s2
    80003182:	00000097          	auipc	ra,0x0
    80003186:	e92080e7          	jalr	-366(ra) # 80003014 <brelse>
}
    8000318a:	60e2                	ld	ra,24(sp)
    8000318c:	6442                	ld	s0,16(sp)
    8000318e:	64a2                	ld	s1,8(sp)
    80003190:	6902                	ld	s2,0(sp)
    80003192:	6105                	addi	sp,sp,32
    80003194:	8082                	ret
    panic("freeing free block");
    80003196:	00005517          	auipc	a0,0x5
    8000319a:	43a50513          	addi	a0,a0,1082 # 800085d0 <syscalls+0x108>
    8000319e:	ffffd097          	auipc	ra,0xffffd
    800031a2:	3a0080e7          	jalr	928(ra) # 8000053e <panic>

00000000800031a6 <balloc>:
{
    800031a6:	711d                	addi	sp,sp,-96
    800031a8:	ec86                	sd	ra,88(sp)
    800031aa:	e8a2                	sd	s0,80(sp)
    800031ac:	e4a6                	sd	s1,72(sp)
    800031ae:	e0ca                	sd	s2,64(sp)
    800031b0:	fc4e                	sd	s3,56(sp)
    800031b2:	f852                	sd	s4,48(sp)
    800031b4:	f456                	sd	s5,40(sp)
    800031b6:	f05a                	sd	s6,32(sp)
    800031b8:	ec5e                	sd	s7,24(sp)
    800031ba:	e862                	sd	s8,16(sp)
    800031bc:	e466                	sd	s9,8(sp)
    800031be:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031c0:	0001c797          	auipc	a5,0x1c
    800031c4:	7ec7a783          	lw	a5,2028(a5) # 8001f9ac <sb+0x4>
    800031c8:	cbd1                	beqz	a5,8000325c <balloc+0xb6>
    800031ca:	8baa                	mv	s7,a0
    800031cc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031ce:	0001cb17          	auipc	s6,0x1c
    800031d2:	7dab0b13          	addi	s6,s6,2010 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031d6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031d8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031da:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031dc:	6c89                	lui	s9,0x2
    800031de:	a831                	j	800031fa <balloc+0x54>
    brelse(bp);
    800031e0:	854a                	mv	a0,s2
    800031e2:	00000097          	auipc	ra,0x0
    800031e6:	e32080e7          	jalr	-462(ra) # 80003014 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031ea:	015c87bb          	addw	a5,s9,s5
    800031ee:	00078a9b          	sext.w	s5,a5
    800031f2:	004b2703          	lw	a4,4(s6)
    800031f6:	06eaf363          	bgeu	s5,a4,8000325c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800031fa:	41fad79b          	sraiw	a5,s5,0x1f
    800031fe:	0137d79b          	srliw	a5,a5,0x13
    80003202:	015787bb          	addw	a5,a5,s5
    80003206:	40d7d79b          	sraiw	a5,a5,0xd
    8000320a:	01cb2583          	lw	a1,28(s6)
    8000320e:	9dbd                	addw	a1,a1,a5
    80003210:	855e                	mv	a0,s7
    80003212:	00000097          	auipc	ra,0x0
    80003216:	cd2080e7          	jalr	-814(ra) # 80002ee4 <bread>
    8000321a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000321c:	004b2503          	lw	a0,4(s6)
    80003220:	000a849b          	sext.w	s1,s5
    80003224:	8662                	mv	a2,s8
    80003226:	faa4fde3          	bgeu	s1,a0,800031e0 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000322a:	41f6579b          	sraiw	a5,a2,0x1f
    8000322e:	01d7d69b          	srliw	a3,a5,0x1d
    80003232:	00c6873b          	addw	a4,a3,a2
    80003236:	00777793          	andi	a5,a4,7
    8000323a:	9f95                	subw	a5,a5,a3
    8000323c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003240:	4037571b          	sraiw	a4,a4,0x3
    80003244:	00e906b3          	add	a3,s2,a4
    80003248:	0586c683          	lbu	a3,88(a3)
    8000324c:	00d7f5b3          	and	a1,a5,a3
    80003250:	cd91                	beqz	a1,8000326c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003252:	2605                	addiw	a2,a2,1
    80003254:	2485                	addiw	s1,s1,1
    80003256:	fd4618e3          	bne	a2,s4,80003226 <balloc+0x80>
    8000325a:	b759                	j	800031e0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000325c:	00005517          	auipc	a0,0x5
    80003260:	38c50513          	addi	a0,a0,908 # 800085e8 <syscalls+0x120>
    80003264:	ffffd097          	auipc	ra,0xffffd
    80003268:	2da080e7          	jalr	730(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000326c:	974a                	add	a4,a4,s2
    8000326e:	8fd5                	or	a5,a5,a3
    80003270:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003274:	854a                	mv	a0,s2
    80003276:	00001097          	auipc	ra,0x1
    8000327a:	01a080e7          	jalr	26(ra) # 80004290 <log_write>
        brelse(bp);
    8000327e:	854a                	mv	a0,s2
    80003280:	00000097          	auipc	ra,0x0
    80003284:	d94080e7          	jalr	-620(ra) # 80003014 <brelse>
  bp = bread(dev, bno);
    80003288:	85a6                	mv	a1,s1
    8000328a:	855e                	mv	a0,s7
    8000328c:	00000097          	auipc	ra,0x0
    80003290:	c58080e7          	jalr	-936(ra) # 80002ee4 <bread>
    80003294:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003296:	40000613          	li	a2,1024
    8000329a:	4581                	li	a1,0
    8000329c:	05850513          	addi	a0,a0,88
    800032a0:	ffffe097          	auipc	ra,0xffffe
    800032a4:	a40080e7          	jalr	-1472(ra) # 80000ce0 <memset>
  log_write(bp);
    800032a8:	854a                	mv	a0,s2
    800032aa:	00001097          	auipc	ra,0x1
    800032ae:	fe6080e7          	jalr	-26(ra) # 80004290 <log_write>
  brelse(bp);
    800032b2:	854a                	mv	a0,s2
    800032b4:	00000097          	auipc	ra,0x0
    800032b8:	d60080e7          	jalr	-672(ra) # 80003014 <brelse>
}
    800032bc:	8526                	mv	a0,s1
    800032be:	60e6                	ld	ra,88(sp)
    800032c0:	6446                	ld	s0,80(sp)
    800032c2:	64a6                	ld	s1,72(sp)
    800032c4:	6906                	ld	s2,64(sp)
    800032c6:	79e2                	ld	s3,56(sp)
    800032c8:	7a42                	ld	s4,48(sp)
    800032ca:	7aa2                	ld	s5,40(sp)
    800032cc:	7b02                	ld	s6,32(sp)
    800032ce:	6be2                	ld	s7,24(sp)
    800032d0:	6c42                	ld	s8,16(sp)
    800032d2:	6ca2                	ld	s9,8(sp)
    800032d4:	6125                	addi	sp,sp,96
    800032d6:	8082                	ret

00000000800032d8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032d8:	7179                	addi	sp,sp,-48
    800032da:	f406                	sd	ra,40(sp)
    800032dc:	f022                	sd	s0,32(sp)
    800032de:	ec26                	sd	s1,24(sp)
    800032e0:	e84a                	sd	s2,16(sp)
    800032e2:	e44e                	sd	s3,8(sp)
    800032e4:	e052                	sd	s4,0(sp)
    800032e6:	1800                	addi	s0,sp,48
    800032e8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032ea:	47ad                	li	a5,11
    800032ec:	04b7fe63          	bgeu	a5,a1,80003348 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032f0:	ff45849b          	addiw	s1,a1,-12
    800032f4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032f8:	0ff00793          	li	a5,255
    800032fc:	0ae7e363          	bltu	a5,a4,800033a2 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003300:	08052583          	lw	a1,128(a0)
    80003304:	c5ad                	beqz	a1,8000336e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003306:	00092503          	lw	a0,0(s2)
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	bda080e7          	jalr	-1062(ra) # 80002ee4 <bread>
    80003312:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003314:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003318:	02049593          	slli	a1,s1,0x20
    8000331c:	9181                	srli	a1,a1,0x20
    8000331e:	058a                	slli	a1,a1,0x2
    80003320:	00b784b3          	add	s1,a5,a1
    80003324:	0004a983          	lw	s3,0(s1)
    80003328:	04098d63          	beqz	s3,80003382 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000332c:	8552                	mv	a0,s4
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	ce6080e7          	jalr	-794(ra) # 80003014 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003336:	854e                	mv	a0,s3
    80003338:	70a2                	ld	ra,40(sp)
    8000333a:	7402                	ld	s0,32(sp)
    8000333c:	64e2                	ld	s1,24(sp)
    8000333e:	6942                	ld	s2,16(sp)
    80003340:	69a2                	ld	s3,8(sp)
    80003342:	6a02                	ld	s4,0(sp)
    80003344:	6145                	addi	sp,sp,48
    80003346:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003348:	02059493          	slli	s1,a1,0x20
    8000334c:	9081                	srli	s1,s1,0x20
    8000334e:	048a                	slli	s1,s1,0x2
    80003350:	94aa                	add	s1,s1,a0
    80003352:	0504a983          	lw	s3,80(s1)
    80003356:	fe0990e3          	bnez	s3,80003336 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000335a:	4108                	lw	a0,0(a0)
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	e4a080e7          	jalr	-438(ra) # 800031a6 <balloc>
    80003364:	0005099b          	sext.w	s3,a0
    80003368:	0534a823          	sw	s3,80(s1)
    8000336c:	b7e9                	j	80003336 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000336e:	4108                	lw	a0,0(a0)
    80003370:	00000097          	auipc	ra,0x0
    80003374:	e36080e7          	jalr	-458(ra) # 800031a6 <balloc>
    80003378:	0005059b          	sext.w	a1,a0
    8000337c:	08b92023          	sw	a1,128(s2)
    80003380:	b759                	j	80003306 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003382:	00092503          	lw	a0,0(s2)
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	e20080e7          	jalr	-480(ra) # 800031a6 <balloc>
    8000338e:	0005099b          	sext.w	s3,a0
    80003392:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003396:	8552                	mv	a0,s4
    80003398:	00001097          	auipc	ra,0x1
    8000339c:	ef8080e7          	jalr	-264(ra) # 80004290 <log_write>
    800033a0:	b771                	j	8000332c <bmap+0x54>
  panic("bmap: out of range");
    800033a2:	00005517          	auipc	a0,0x5
    800033a6:	25e50513          	addi	a0,a0,606 # 80008600 <syscalls+0x138>
    800033aa:	ffffd097          	auipc	ra,0xffffd
    800033ae:	194080e7          	jalr	404(ra) # 8000053e <panic>

00000000800033b2 <iget>:
{
    800033b2:	7179                	addi	sp,sp,-48
    800033b4:	f406                	sd	ra,40(sp)
    800033b6:	f022                	sd	s0,32(sp)
    800033b8:	ec26                	sd	s1,24(sp)
    800033ba:	e84a                	sd	s2,16(sp)
    800033bc:	e44e                	sd	s3,8(sp)
    800033be:	e052                	sd	s4,0(sp)
    800033c0:	1800                	addi	s0,sp,48
    800033c2:	89aa                	mv	s3,a0
    800033c4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033c6:	0001c517          	auipc	a0,0x1c
    800033ca:	60250513          	addi	a0,a0,1538 # 8001f9c8 <itable>
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	816080e7          	jalr	-2026(ra) # 80000be4 <acquire>
  empty = 0;
    800033d6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033d8:	0001c497          	auipc	s1,0x1c
    800033dc:	60848493          	addi	s1,s1,1544 # 8001f9e0 <itable+0x18>
    800033e0:	0001e697          	auipc	a3,0x1e
    800033e4:	09068693          	addi	a3,a3,144 # 80021470 <log>
    800033e8:	a039                	j	800033f6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ea:	02090b63          	beqz	s2,80003420 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033ee:	08848493          	addi	s1,s1,136
    800033f2:	02d48a63          	beq	s1,a3,80003426 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033f6:	449c                	lw	a5,8(s1)
    800033f8:	fef059e3          	blez	a5,800033ea <iget+0x38>
    800033fc:	4098                	lw	a4,0(s1)
    800033fe:	ff3716e3          	bne	a4,s3,800033ea <iget+0x38>
    80003402:	40d8                	lw	a4,4(s1)
    80003404:	ff4713e3          	bne	a4,s4,800033ea <iget+0x38>
      ip->ref++;
    80003408:	2785                	addiw	a5,a5,1
    8000340a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000340c:	0001c517          	auipc	a0,0x1c
    80003410:	5bc50513          	addi	a0,a0,1468 # 8001f9c8 <itable>
    80003414:	ffffe097          	auipc	ra,0xffffe
    80003418:	884080e7          	jalr	-1916(ra) # 80000c98 <release>
      return ip;
    8000341c:	8926                	mv	s2,s1
    8000341e:	a03d                	j	8000344c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003420:	f7f9                	bnez	a5,800033ee <iget+0x3c>
    80003422:	8926                	mv	s2,s1
    80003424:	b7e9                	j	800033ee <iget+0x3c>
  if(empty == 0)
    80003426:	02090c63          	beqz	s2,8000345e <iget+0xac>
  ip->dev = dev;
    8000342a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000342e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003432:	4785                	li	a5,1
    80003434:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003438:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000343c:	0001c517          	auipc	a0,0x1c
    80003440:	58c50513          	addi	a0,a0,1420 # 8001f9c8 <itable>
    80003444:	ffffe097          	auipc	ra,0xffffe
    80003448:	854080e7          	jalr	-1964(ra) # 80000c98 <release>
}
    8000344c:	854a                	mv	a0,s2
    8000344e:	70a2                	ld	ra,40(sp)
    80003450:	7402                	ld	s0,32(sp)
    80003452:	64e2                	ld	s1,24(sp)
    80003454:	6942                	ld	s2,16(sp)
    80003456:	69a2                	ld	s3,8(sp)
    80003458:	6a02                	ld	s4,0(sp)
    8000345a:	6145                	addi	sp,sp,48
    8000345c:	8082                	ret
    panic("iget: no inodes");
    8000345e:	00005517          	auipc	a0,0x5
    80003462:	1ba50513          	addi	a0,a0,442 # 80008618 <syscalls+0x150>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	0d8080e7          	jalr	216(ra) # 8000053e <panic>

000000008000346e <fsinit>:
fsinit(int dev) {
    8000346e:	7179                	addi	sp,sp,-48
    80003470:	f406                	sd	ra,40(sp)
    80003472:	f022                	sd	s0,32(sp)
    80003474:	ec26                	sd	s1,24(sp)
    80003476:	e84a                	sd	s2,16(sp)
    80003478:	e44e                	sd	s3,8(sp)
    8000347a:	1800                	addi	s0,sp,48
    8000347c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000347e:	4585                	li	a1,1
    80003480:	00000097          	auipc	ra,0x0
    80003484:	a64080e7          	jalr	-1436(ra) # 80002ee4 <bread>
    80003488:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000348a:	0001c997          	auipc	s3,0x1c
    8000348e:	51e98993          	addi	s3,s3,1310 # 8001f9a8 <sb>
    80003492:	02000613          	li	a2,32
    80003496:	05850593          	addi	a1,a0,88
    8000349a:	854e                	mv	a0,s3
    8000349c:	ffffe097          	auipc	ra,0xffffe
    800034a0:	8a4080e7          	jalr	-1884(ra) # 80000d40 <memmove>
  brelse(bp);
    800034a4:	8526                	mv	a0,s1
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	b6e080e7          	jalr	-1170(ra) # 80003014 <brelse>
  if(sb.magic != FSMAGIC)
    800034ae:	0009a703          	lw	a4,0(s3)
    800034b2:	102037b7          	lui	a5,0x10203
    800034b6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034ba:	02f71263          	bne	a4,a5,800034de <fsinit+0x70>
  initlog(dev, &sb);
    800034be:	0001c597          	auipc	a1,0x1c
    800034c2:	4ea58593          	addi	a1,a1,1258 # 8001f9a8 <sb>
    800034c6:	854a                	mv	a0,s2
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	b4c080e7          	jalr	-1204(ra) # 80004014 <initlog>
}
    800034d0:	70a2                	ld	ra,40(sp)
    800034d2:	7402                	ld	s0,32(sp)
    800034d4:	64e2                	ld	s1,24(sp)
    800034d6:	6942                	ld	s2,16(sp)
    800034d8:	69a2                	ld	s3,8(sp)
    800034da:	6145                	addi	sp,sp,48
    800034dc:	8082                	ret
    panic("invalid file system");
    800034de:	00005517          	auipc	a0,0x5
    800034e2:	14a50513          	addi	a0,a0,330 # 80008628 <syscalls+0x160>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	058080e7          	jalr	88(ra) # 8000053e <panic>

00000000800034ee <iinit>:
{
    800034ee:	7179                	addi	sp,sp,-48
    800034f0:	f406                	sd	ra,40(sp)
    800034f2:	f022                	sd	s0,32(sp)
    800034f4:	ec26                	sd	s1,24(sp)
    800034f6:	e84a                	sd	s2,16(sp)
    800034f8:	e44e                	sd	s3,8(sp)
    800034fa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034fc:	00005597          	auipc	a1,0x5
    80003500:	14458593          	addi	a1,a1,324 # 80008640 <syscalls+0x178>
    80003504:	0001c517          	auipc	a0,0x1c
    80003508:	4c450513          	addi	a0,a0,1220 # 8001f9c8 <itable>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	648080e7          	jalr	1608(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003514:	0001c497          	auipc	s1,0x1c
    80003518:	4dc48493          	addi	s1,s1,1244 # 8001f9f0 <itable+0x28>
    8000351c:	0001e997          	auipc	s3,0x1e
    80003520:	f6498993          	addi	s3,s3,-156 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003524:	00005917          	auipc	s2,0x5
    80003528:	12490913          	addi	s2,s2,292 # 80008648 <syscalls+0x180>
    8000352c:	85ca                	mv	a1,s2
    8000352e:	8526                	mv	a0,s1
    80003530:	00001097          	auipc	ra,0x1
    80003534:	e46080e7          	jalr	-442(ra) # 80004376 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003538:	08848493          	addi	s1,s1,136
    8000353c:	ff3498e3          	bne	s1,s3,8000352c <iinit+0x3e>
}
    80003540:	70a2                	ld	ra,40(sp)
    80003542:	7402                	ld	s0,32(sp)
    80003544:	64e2                	ld	s1,24(sp)
    80003546:	6942                	ld	s2,16(sp)
    80003548:	69a2                	ld	s3,8(sp)
    8000354a:	6145                	addi	sp,sp,48
    8000354c:	8082                	ret

000000008000354e <ialloc>:
{
    8000354e:	715d                	addi	sp,sp,-80
    80003550:	e486                	sd	ra,72(sp)
    80003552:	e0a2                	sd	s0,64(sp)
    80003554:	fc26                	sd	s1,56(sp)
    80003556:	f84a                	sd	s2,48(sp)
    80003558:	f44e                	sd	s3,40(sp)
    8000355a:	f052                	sd	s4,32(sp)
    8000355c:	ec56                	sd	s5,24(sp)
    8000355e:	e85a                	sd	s6,16(sp)
    80003560:	e45e                	sd	s7,8(sp)
    80003562:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003564:	0001c717          	auipc	a4,0x1c
    80003568:	45072703          	lw	a4,1104(a4) # 8001f9b4 <sb+0xc>
    8000356c:	4785                	li	a5,1
    8000356e:	04e7fa63          	bgeu	a5,a4,800035c2 <ialloc+0x74>
    80003572:	8aaa                	mv	s5,a0
    80003574:	8bae                	mv	s7,a1
    80003576:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003578:	0001ca17          	auipc	s4,0x1c
    8000357c:	430a0a13          	addi	s4,s4,1072 # 8001f9a8 <sb>
    80003580:	00048b1b          	sext.w	s6,s1
    80003584:	0044d593          	srli	a1,s1,0x4
    80003588:	018a2783          	lw	a5,24(s4)
    8000358c:	9dbd                	addw	a1,a1,a5
    8000358e:	8556                	mv	a0,s5
    80003590:	00000097          	auipc	ra,0x0
    80003594:	954080e7          	jalr	-1708(ra) # 80002ee4 <bread>
    80003598:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000359a:	05850993          	addi	s3,a0,88
    8000359e:	00f4f793          	andi	a5,s1,15
    800035a2:	079a                	slli	a5,a5,0x6
    800035a4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035a6:	00099783          	lh	a5,0(s3)
    800035aa:	c785                	beqz	a5,800035d2 <ialloc+0x84>
    brelse(bp);
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	a68080e7          	jalr	-1432(ra) # 80003014 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035b4:	0485                	addi	s1,s1,1
    800035b6:	00ca2703          	lw	a4,12(s4)
    800035ba:	0004879b          	sext.w	a5,s1
    800035be:	fce7e1e3          	bltu	a5,a4,80003580 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035c2:	00005517          	auipc	a0,0x5
    800035c6:	08e50513          	addi	a0,a0,142 # 80008650 <syscalls+0x188>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	f74080e7          	jalr	-140(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800035d2:	04000613          	li	a2,64
    800035d6:	4581                	li	a1,0
    800035d8:	854e                	mv	a0,s3
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	706080e7          	jalr	1798(ra) # 80000ce0 <memset>
      dip->type = type;
    800035e2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035e6:	854a                	mv	a0,s2
    800035e8:	00001097          	auipc	ra,0x1
    800035ec:	ca8080e7          	jalr	-856(ra) # 80004290 <log_write>
      brelse(bp);
    800035f0:	854a                	mv	a0,s2
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	a22080e7          	jalr	-1502(ra) # 80003014 <brelse>
      return iget(dev, inum);
    800035fa:	85da                	mv	a1,s6
    800035fc:	8556                	mv	a0,s5
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	db4080e7          	jalr	-588(ra) # 800033b2 <iget>
}
    80003606:	60a6                	ld	ra,72(sp)
    80003608:	6406                	ld	s0,64(sp)
    8000360a:	74e2                	ld	s1,56(sp)
    8000360c:	7942                	ld	s2,48(sp)
    8000360e:	79a2                	ld	s3,40(sp)
    80003610:	7a02                	ld	s4,32(sp)
    80003612:	6ae2                	ld	s5,24(sp)
    80003614:	6b42                	ld	s6,16(sp)
    80003616:	6ba2                	ld	s7,8(sp)
    80003618:	6161                	addi	sp,sp,80
    8000361a:	8082                	ret

000000008000361c <iupdate>:
{
    8000361c:	1101                	addi	sp,sp,-32
    8000361e:	ec06                	sd	ra,24(sp)
    80003620:	e822                	sd	s0,16(sp)
    80003622:	e426                	sd	s1,8(sp)
    80003624:	e04a                	sd	s2,0(sp)
    80003626:	1000                	addi	s0,sp,32
    80003628:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000362a:	415c                	lw	a5,4(a0)
    8000362c:	0047d79b          	srliw	a5,a5,0x4
    80003630:	0001c597          	auipc	a1,0x1c
    80003634:	3905a583          	lw	a1,912(a1) # 8001f9c0 <sb+0x18>
    80003638:	9dbd                	addw	a1,a1,a5
    8000363a:	4108                	lw	a0,0(a0)
    8000363c:	00000097          	auipc	ra,0x0
    80003640:	8a8080e7          	jalr	-1880(ra) # 80002ee4 <bread>
    80003644:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003646:	05850793          	addi	a5,a0,88
    8000364a:	40c8                	lw	a0,4(s1)
    8000364c:	893d                	andi	a0,a0,15
    8000364e:	051a                	slli	a0,a0,0x6
    80003650:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003652:	04449703          	lh	a4,68(s1)
    80003656:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000365a:	04649703          	lh	a4,70(s1)
    8000365e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003662:	04849703          	lh	a4,72(s1)
    80003666:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000366a:	04a49703          	lh	a4,74(s1)
    8000366e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003672:	44f8                	lw	a4,76(s1)
    80003674:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003676:	03400613          	li	a2,52
    8000367a:	05048593          	addi	a1,s1,80
    8000367e:	0531                	addi	a0,a0,12
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	6c0080e7          	jalr	1728(ra) # 80000d40 <memmove>
  log_write(bp);
    80003688:	854a                	mv	a0,s2
    8000368a:	00001097          	auipc	ra,0x1
    8000368e:	c06080e7          	jalr	-1018(ra) # 80004290 <log_write>
  brelse(bp);
    80003692:	854a                	mv	a0,s2
    80003694:	00000097          	auipc	ra,0x0
    80003698:	980080e7          	jalr	-1664(ra) # 80003014 <brelse>
}
    8000369c:	60e2                	ld	ra,24(sp)
    8000369e:	6442                	ld	s0,16(sp)
    800036a0:	64a2                	ld	s1,8(sp)
    800036a2:	6902                	ld	s2,0(sp)
    800036a4:	6105                	addi	sp,sp,32
    800036a6:	8082                	ret

00000000800036a8 <idup>:
{
    800036a8:	1101                	addi	sp,sp,-32
    800036aa:	ec06                	sd	ra,24(sp)
    800036ac:	e822                	sd	s0,16(sp)
    800036ae:	e426                	sd	s1,8(sp)
    800036b0:	1000                	addi	s0,sp,32
    800036b2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036b4:	0001c517          	auipc	a0,0x1c
    800036b8:	31450513          	addi	a0,a0,788 # 8001f9c8 <itable>
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	528080e7          	jalr	1320(ra) # 80000be4 <acquire>
  ip->ref++;
    800036c4:	449c                	lw	a5,8(s1)
    800036c6:	2785                	addiw	a5,a5,1
    800036c8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036ca:	0001c517          	auipc	a0,0x1c
    800036ce:	2fe50513          	addi	a0,a0,766 # 8001f9c8 <itable>
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	5c6080e7          	jalr	1478(ra) # 80000c98 <release>
}
    800036da:	8526                	mv	a0,s1
    800036dc:	60e2                	ld	ra,24(sp)
    800036de:	6442                	ld	s0,16(sp)
    800036e0:	64a2                	ld	s1,8(sp)
    800036e2:	6105                	addi	sp,sp,32
    800036e4:	8082                	ret

00000000800036e6 <ilock>:
{
    800036e6:	1101                	addi	sp,sp,-32
    800036e8:	ec06                	sd	ra,24(sp)
    800036ea:	e822                	sd	s0,16(sp)
    800036ec:	e426                	sd	s1,8(sp)
    800036ee:	e04a                	sd	s2,0(sp)
    800036f0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036f2:	c115                	beqz	a0,80003716 <ilock+0x30>
    800036f4:	84aa                	mv	s1,a0
    800036f6:	451c                	lw	a5,8(a0)
    800036f8:	00f05f63          	blez	a5,80003716 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036fc:	0541                	addi	a0,a0,16
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	cb2080e7          	jalr	-846(ra) # 800043b0 <acquiresleep>
  if(ip->valid == 0){
    80003706:	40bc                	lw	a5,64(s1)
    80003708:	cf99                	beqz	a5,80003726 <ilock+0x40>
}
    8000370a:	60e2                	ld	ra,24(sp)
    8000370c:	6442                	ld	s0,16(sp)
    8000370e:	64a2                	ld	s1,8(sp)
    80003710:	6902                	ld	s2,0(sp)
    80003712:	6105                	addi	sp,sp,32
    80003714:	8082                	ret
    panic("ilock");
    80003716:	00005517          	auipc	a0,0x5
    8000371a:	f5250513          	addi	a0,a0,-174 # 80008668 <syscalls+0x1a0>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	e20080e7          	jalr	-480(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003726:	40dc                	lw	a5,4(s1)
    80003728:	0047d79b          	srliw	a5,a5,0x4
    8000372c:	0001c597          	auipc	a1,0x1c
    80003730:	2945a583          	lw	a1,660(a1) # 8001f9c0 <sb+0x18>
    80003734:	9dbd                	addw	a1,a1,a5
    80003736:	4088                	lw	a0,0(s1)
    80003738:	fffff097          	auipc	ra,0xfffff
    8000373c:	7ac080e7          	jalr	1964(ra) # 80002ee4 <bread>
    80003740:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003742:	05850593          	addi	a1,a0,88
    80003746:	40dc                	lw	a5,4(s1)
    80003748:	8bbd                	andi	a5,a5,15
    8000374a:	079a                	slli	a5,a5,0x6
    8000374c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000374e:	00059783          	lh	a5,0(a1)
    80003752:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003756:	00259783          	lh	a5,2(a1)
    8000375a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000375e:	00459783          	lh	a5,4(a1)
    80003762:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003766:	00659783          	lh	a5,6(a1)
    8000376a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000376e:	459c                	lw	a5,8(a1)
    80003770:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003772:	03400613          	li	a2,52
    80003776:	05b1                	addi	a1,a1,12
    80003778:	05048513          	addi	a0,s1,80
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	5c4080e7          	jalr	1476(ra) # 80000d40 <memmove>
    brelse(bp);
    80003784:	854a                	mv	a0,s2
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	88e080e7          	jalr	-1906(ra) # 80003014 <brelse>
    ip->valid = 1;
    8000378e:	4785                	li	a5,1
    80003790:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003792:	04449783          	lh	a5,68(s1)
    80003796:	fbb5                	bnez	a5,8000370a <ilock+0x24>
      panic("ilock: no type");
    80003798:	00005517          	auipc	a0,0x5
    8000379c:	ed850513          	addi	a0,a0,-296 # 80008670 <syscalls+0x1a8>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	d9e080e7          	jalr	-610(ra) # 8000053e <panic>

00000000800037a8 <iunlock>:
{
    800037a8:	1101                	addi	sp,sp,-32
    800037aa:	ec06                	sd	ra,24(sp)
    800037ac:	e822                	sd	s0,16(sp)
    800037ae:	e426                	sd	s1,8(sp)
    800037b0:	e04a                	sd	s2,0(sp)
    800037b2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037b4:	c905                	beqz	a0,800037e4 <iunlock+0x3c>
    800037b6:	84aa                	mv	s1,a0
    800037b8:	01050913          	addi	s2,a0,16
    800037bc:	854a                	mv	a0,s2
    800037be:	00001097          	auipc	ra,0x1
    800037c2:	c8c080e7          	jalr	-884(ra) # 8000444a <holdingsleep>
    800037c6:	cd19                	beqz	a0,800037e4 <iunlock+0x3c>
    800037c8:	449c                	lw	a5,8(s1)
    800037ca:	00f05d63          	blez	a5,800037e4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037ce:	854a                	mv	a0,s2
    800037d0:	00001097          	auipc	ra,0x1
    800037d4:	c36080e7          	jalr	-970(ra) # 80004406 <releasesleep>
}
    800037d8:	60e2                	ld	ra,24(sp)
    800037da:	6442                	ld	s0,16(sp)
    800037dc:	64a2                	ld	s1,8(sp)
    800037de:	6902                	ld	s2,0(sp)
    800037e0:	6105                	addi	sp,sp,32
    800037e2:	8082                	ret
    panic("iunlock");
    800037e4:	00005517          	auipc	a0,0x5
    800037e8:	e9c50513          	addi	a0,a0,-356 # 80008680 <syscalls+0x1b8>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	d52080e7          	jalr	-686(ra) # 8000053e <panic>

00000000800037f4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037f4:	7179                	addi	sp,sp,-48
    800037f6:	f406                	sd	ra,40(sp)
    800037f8:	f022                	sd	s0,32(sp)
    800037fa:	ec26                	sd	s1,24(sp)
    800037fc:	e84a                	sd	s2,16(sp)
    800037fe:	e44e                	sd	s3,8(sp)
    80003800:	e052                	sd	s4,0(sp)
    80003802:	1800                	addi	s0,sp,48
    80003804:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003806:	05050493          	addi	s1,a0,80
    8000380a:	08050913          	addi	s2,a0,128
    8000380e:	a021                	j	80003816 <itrunc+0x22>
    80003810:	0491                	addi	s1,s1,4
    80003812:	01248d63          	beq	s1,s2,8000382c <itrunc+0x38>
    if(ip->addrs[i]){
    80003816:	408c                	lw	a1,0(s1)
    80003818:	dde5                	beqz	a1,80003810 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000381a:	0009a503          	lw	a0,0(s3)
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	90c080e7          	jalr	-1780(ra) # 8000312a <bfree>
      ip->addrs[i] = 0;
    80003826:	0004a023          	sw	zero,0(s1)
    8000382a:	b7dd                	j	80003810 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000382c:	0809a583          	lw	a1,128(s3)
    80003830:	e185                	bnez	a1,80003850 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003832:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003836:	854e                	mv	a0,s3
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	de4080e7          	jalr	-540(ra) # 8000361c <iupdate>
}
    80003840:	70a2                	ld	ra,40(sp)
    80003842:	7402                	ld	s0,32(sp)
    80003844:	64e2                	ld	s1,24(sp)
    80003846:	6942                	ld	s2,16(sp)
    80003848:	69a2                	ld	s3,8(sp)
    8000384a:	6a02                	ld	s4,0(sp)
    8000384c:	6145                	addi	sp,sp,48
    8000384e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003850:	0009a503          	lw	a0,0(s3)
    80003854:	fffff097          	auipc	ra,0xfffff
    80003858:	690080e7          	jalr	1680(ra) # 80002ee4 <bread>
    8000385c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000385e:	05850493          	addi	s1,a0,88
    80003862:	45850913          	addi	s2,a0,1112
    80003866:	a811                	j	8000387a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003868:	0009a503          	lw	a0,0(s3)
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	8be080e7          	jalr	-1858(ra) # 8000312a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003874:	0491                	addi	s1,s1,4
    80003876:	01248563          	beq	s1,s2,80003880 <itrunc+0x8c>
      if(a[j])
    8000387a:	408c                	lw	a1,0(s1)
    8000387c:	dde5                	beqz	a1,80003874 <itrunc+0x80>
    8000387e:	b7ed                	j	80003868 <itrunc+0x74>
    brelse(bp);
    80003880:	8552                	mv	a0,s4
    80003882:	fffff097          	auipc	ra,0xfffff
    80003886:	792080e7          	jalr	1938(ra) # 80003014 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000388a:	0809a583          	lw	a1,128(s3)
    8000388e:	0009a503          	lw	a0,0(s3)
    80003892:	00000097          	auipc	ra,0x0
    80003896:	898080e7          	jalr	-1896(ra) # 8000312a <bfree>
    ip->addrs[NDIRECT] = 0;
    8000389a:	0809a023          	sw	zero,128(s3)
    8000389e:	bf51                	j	80003832 <itrunc+0x3e>

00000000800038a0 <iput>:
{
    800038a0:	1101                	addi	sp,sp,-32
    800038a2:	ec06                	sd	ra,24(sp)
    800038a4:	e822                	sd	s0,16(sp)
    800038a6:	e426                	sd	s1,8(sp)
    800038a8:	e04a                	sd	s2,0(sp)
    800038aa:	1000                	addi	s0,sp,32
    800038ac:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038ae:	0001c517          	auipc	a0,0x1c
    800038b2:	11a50513          	addi	a0,a0,282 # 8001f9c8 <itable>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	32e080e7          	jalr	814(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038be:	4498                	lw	a4,8(s1)
    800038c0:	4785                	li	a5,1
    800038c2:	02f70363          	beq	a4,a5,800038e8 <iput+0x48>
  ip->ref--;
    800038c6:	449c                	lw	a5,8(s1)
    800038c8:	37fd                	addiw	a5,a5,-1
    800038ca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038cc:	0001c517          	auipc	a0,0x1c
    800038d0:	0fc50513          	addi	a0,a0,252 # 8001f9c8 <itable>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	3c4080e7          	jalr	964(ra) # 80000c98 <release>
}
    800038dc:	60e2                	ld	ra,24(sp)
    800038de:	6442                	ld	s0,16(sp)
    800038e0:	64a2                	ld	s1,8(sp)
    800038e2:	6902                	ld	s2,0(sp)
    800038e4:	6105                	addi	sp,sp,32
    800038e6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038e8:	40bc                	lw	a5,64(s1)
    800038ea:	dff1                	beqz	a5,800038c6 <iput+0x26>
    800038ec:	04a49783          	lh	a5,74(s1)
    800038f0:	fbf9                	bnez	a5,800038c6 <iput+0x26>
    acquiresleep(&ip->lock);
    800038f2:	01048913          	addi	s2,s1,16
    800038f6:	854a                	mv	a0,s2
    800038f8:	00001097          	auipc	ra,0x1
    800038fc:	ab8080e7          	jalr	-1352(ra) # 800043b0 <acquiresleep>
    release(&itable.lock);
    80003900:	0001c517          	auipc	a0,0x1c
    80003904:	0c850513          	addi	a0,a0,200 # 8001f9c8 <itable>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	390080e7          	jalr	912(ra) # 80000c98 <release>
    itrunc(ip);
    80003910:	8526                	mv	a0,s1
    80003912:	00000097          	auipc	ra,0x0
    80003916:	ee2080e7          	jalr	-286(ra) # 800037f4 <itrunc>
    ip->type = 0;
    8000391a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000391e:	8526                	mv	a0,s1
    80003920:	00000097          	auipc	ra,0x0
    80003924:	cfc080e7          	jalr	-772(ra) # 8000361c <iupdate>
    ip->valid = 0;
    80003928:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000392c:	854a                	mv	a0,s2
    8000392e:	00001097          	auipc	ra,0x1
    80003932:	ad8080e7          	jalr	-1320(ra) # 80004406 <releasesleep>
    acquire(&itable.lock);
    80003936:	0001c517          	auipc	a0,0x1c
    8000393a:	09250513          	addi	a0,a0,146 # 8001f9c8 <itable>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	2a6080e7          	jalr	678(ra) # 80000be4 <acquire>
    80003946:	b741                	j	800038c6 <iput+0x26>

0000000080003948 <iunlockput>:
{
    80003948:	1101                	addi	sp,sp,-32
    8000394a:	ec06                	sd	ra,24(sp)
    8000394c:	e822                	sd	s0,16(sp)
    8000394e:	e426                	sd	s1,8(sp)
    80003950:	1000                	addi	s0,sp,32
    80003952:	84aa                	mv	s1,a0
  iunlock(ip);
    80003954:	00000097          	auipc	ra,0x0
    80003958:	e54080e7          	jalr	-428(ra) # 800037a8 <iunlock>
  iput(ip);
    8000395c:	8526                	mv	a0,s1
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	f42080e7          	jalr	-190(ra) # 800038a0 <iput>
}
    80003966:	60e2                	ld	ra,24(sp)
    80003968:	6442                	ld	s0,16(sp)
    8000396a:	64a2                	ld	s1,8(sp)
    8000396c:	6105                	addi	sp,sp,32
    8000396e:	8082                	ret

0000000080003970 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003970:	1141                	addi	sp,sp,-16
    80003972:	e422                	sd	s0,8(sp)
    80003974:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003976:	411c                	lw	a5,0(a0)
    80003978:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000397a:	415c                	lw	a5,4(a0)
    8000397c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000397e:	04451783          	lh	a5,68(a0)
    80003982:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003986:	04a51783          	lh	a5,74(a0)
    8000398a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000398e:	04c56783          	lwu	a5,76(a0)
    80003992:	e99c                	sd	a5,16(a1)
}
    80003994:	6422                	ld	s0,8(sp)
    80003996:	0141                	addi	sp,sp,16
    80003998:	8082                	ret

000000008000399a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000399a:	457c                	lw	a5,76(a0)
    8000399c:	0ed7e963          	bltu	a5,a3,80003a8e <readi+0xf4>
{
    800039a0:	7159                	addi	sp,sp,-112
    800039a2:	f486                	sd	ra,104(sp)
    800039a4:	f0a2                	sd	s0,96(sp)
    800039a6:	eca6                	sd	s1,88(sp)
    800039a8:	e8ca                	sd	s2,80(sp)
    800039aa:	e4ce                	sd	s3,72(sp)
    800039ac:	e0d2                	sd	s4,64(sp)
    800039ae:	fc56                	sd	s5,56(sp)
    800039b0:	f85a                	sd	s6,48(sp)
    800039b2:	f45e                	sd	s7,40(sp)
    800039b4:	f062                	sd	s8,32(sp)
    800039b6:	ec66                	sd	s9,24(sp)
    800039b8:	e86a                	sd	s10,16(sp)
    800039ba:	e46e                	sd	s11,8(sp)
    800039bc:	1880                	addi	s0,sp,112
    800039be:	8baa                	mv	s7,a0
    800039c0:	8c2e                	mv	s8,a1
    800039c2:	8ab2                	mv	s5,a2
    800039c4:	84b6                	mv	s1,a3
    800039c6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039c8:	9f35                	addw	a4,a4,a3
    return 0;
    800039ca:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039cc:	0ad76063          	bltu	a4,a3,80003a6c <readi+0xd2>
  if(off + n > ip->size)
    800039d0:	00e7f463          	bgeu	a5,a4,800039d8 <readi+0x3e>
    n = ip->size - off;
    800039d4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039d8:	0a0b0963          	beqz	s6,80003a8a <readi+0xf0>
    800039dc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039de:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039e2:	5cfd                	li	s9,-1
    800039e4:	a82d                	j	80003a1e <readi+0x84>
    800039e6:	020a1d93          	slli	s11,s4,0x20
    800039ea:	020ddd93          	srli	s11,s11,0x20
    800039ee:	05890613          	addi	a2,s2,88
    800039f2:	86ee                	mv	a3,s11
    800039f4:	963a                	add	a2,a2,a4
    800039f6:	85d6                	mv	a1,s5
    800039f8:	8562                	mv	a0,s8
    800039fa:	fffff097          	auipc	ra,0xfffff
    800039fe:	abc080e7          	jalr	-1348(ra) # 800024b6 <either_copyout>
    80003a02:	05950d63          	beq	a0,s9,80003a5c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a06:	854a                	mv	a0,s2
    80003a08:	fffff097          	auipc	ra,0xfffff
    80003a0c:	60c080e7          	jalr	1548(ra) # 80003014 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a10:	013a09bb          	addw	s3,s4,s3
    80003a14:	009a04bb          	addw	s1,s4,s1
    80003a18:	9aee                	add	s5,s5,s11
    80003a1a:	0569f763          	bgeu	s3,s6,80003a68 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a1e:	000ba903          	lw	s2,0(s7)
    80003a22:	00a4d59b          	srliw	a1,s1,0xa
    80003a26:	855e                	mv	a0,s7
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	8b0080e7          	jalr	-1872(ra) # 800032d8 <bmap>
    80003a30:	0005059b          	sext.w	a1,a0
    80003a34:	854a                	mv	a0,s2
    80003a36:	fffff097          	auipc	ra,0xfffff
    80003a3a:	4ae080e7          	jalr	1198(ra) # 80002ee4 <bread>
    80003a3e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a40:	3ff4f713          	andi	a4,s1,1023
    80003a44:	40ed07bb          	subw	a5,s10,a4
    80003a48:	413b06bb          	subw	a3,s6,s3
    80003a4c:	8a3e                	mv	s4,a5
    80003a4e:	2781                	sext.w	a5,a5
    80003a50:	0006861b          	sext.w	a2,a3
    80003a54:	f8f679e3          	bgeu	a2,a5,800039e6 <readi+0x4c>
    80003a58:	8a36                	mv	s4,a3
    80003a5a:	b771                	j	800039e6 <readi+0x4c>
      brelse(bp);
    80003a5c:	854a                	mv	a0,s2
    80003a5e:	fffff097          	auipc	ra,0xfffff
    80003a62:	5b6080e7          	jalr	1462(ra) # 80003014 <brelse>
      tot = -1;
    80003a66:	59fd                	li	s3,-1
  }
  return tot;
    80003a68:	0009851b          	sext.w	a0,s3
}
    80003a6c:	70a6                	ld	ra,104(sp)
    80003a6e:	7406                	ld	s0,96(sp)
    80003a70:	64e6                	ld	s1,88(sp)
    80003a72:	6946                	ld	s2,80(sp)
    80003a74:	69a6                	ld	s3,72(sp)
    80003a76:	6a06                	ld	s4,64(sp)
    80003a78:	7ae2                	ld	s5,56(sp)
    80003a7a:	7b42                	ld	s6,48(sp)
    80003a7c:	7ba2                	ld	s7,40(sp)
    80003a7e:	7c02                	ld	s8,32(sp)
    80003a80:	6ce2                	ld	s9,24(sp)
    80003a82:	6d42                	ld	s10,16(sp)
    80003a84:	6da2                	ld	s11,8(sp)
    80003a86:	6165                	addi	sp,sp,112
    80003a88:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a8a:	89da                	mv	s3,s6
    80003a8c:	bff1                	j	80003a68 <readi+0xce>
    return 0;
    80003a8e:	4501                	li	a0,0
}
    80003a90:	8082                	ret

0000000080003a92 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a92:	457c                	lw	a5,76(a0)
    80003a94:	10d7e863          	bltu	a5,a3,80003ba4 <writei+0x112>
{
    80003a98:	7159                	addi	sp,sp,-112
    80003a9a:	f486                	sd	ra,104(sp)
    80003a9c:	f0a2                	sd	s0,96(sp)
    80003a9e:	eca6                	sd	s1,88(sp)
    80003aa0:	e8ca                	sd	s2,80(sp)
    80003aa2:	e4ce                	sd	s3,72(sp)
    80003aa4:	e0d2                	sd	s4,64(sp)
    80003aa6:	fc56                	sd	s5,56(sp)
    80003aa8:	f85a                	sd	s6,48(sp)
    80003aaa:	f45e                	sd	s7,40(sp)
    80003aac:	f062                	sd	s8,32(sp)
    80003aae:	ec66                	sd	s9,24(sp)
    80003ab0:	e86a                	sd	s10,16(sp)
    80003ab2:	e46e                	sd	s11,8(sp)
    80003ab4:	1880                	addi	s0,sp,112
    80003ab6:	8b2a                	mv	s6,a0
    80003ab8:	8c2e                	mv	s8,a1
    80003aba:	8ab2                	mv	s5,a2
    80003abc:	8936                	mv	s2,a3
    80003abe:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ac0:	00e687bb          	addw	a5,a3,a4
    80003ac4:	0ed7e263          	bltu	a5,a3,80003ba8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ac8:	00043737          	lui	a4,0x43
    80003acc:	0ef76063          	bltu	a4,a5,80003bac <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ad0:	0c0b8863          	beqz	s7,80003ba0 <writei+0x10e>
    80003ad4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ada:	5cfd                	li	s9,-1
    80003adc:	a091                	j	80003b20 <writei+0x8e>
    80003ade:	02099d93          	slli	s11,s3,0x20
    80003ae2:	020ddd93          	srli	s11,s11,0x20
    80003ae6:	05848513          	addi	a0,s1,88
    80003aea:	86ee                	mv	a3,s11
    80003aec:	8656                	mv	a2,s5
    80003aee:	85e2                	mv	a1,s8
    80003af0:	953a                	add	a0,a0,a4
    80003af2:	fffff097          	auipc	ra,0xfffff
    80003af6:	a1a080e7          	jalr	-1510(ra) # 8000250c <either_copyin>
    80003afa:	07950263          	beq	a0,s9,80003b5e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003afe:	8526                	mv	a0,s1
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	790080e7          	jalr	1936(ra) # 80004290 <log_write>
    brelse(bp);
    80003b08:	8526                	mv	a0,s1
    80003b0a:	fffff097          	auipc	ra,0xfffff
    80003b0e:	50a080e7          	jalr	1290(ra) # 80003014 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b12:	01498a3b          	addw	s4,s3,s4
    80003b16:	0129893b          	addw	s2,s3,s2
    80003b1a:	9aee                	add	s5,s5,s11
    80003b1c:	057a7663          	bgeu	s4,s7,80003b68 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b20:	000b2483          	lw	s1,0(s6)
    80003b24:	00a9559b          	srliw	a1,s2,0xa
    80003b28:	855a                	mv	a0,s6
    80003b2a:	fffff097          	auipc	ra,0xfffff
    80003b2e:	7ae080e7          	jalr	1966(ra) # 800032d8 <bmap>
    80003b32:	0005059b          	sext.w	a1,a0
    80003b36:	8526                	mv	a0,s1
    80003b38:	fffff097          	auipc	ra,0xfffff
    80003b3c:	3ac080e7          	jalr	940(ra) # 80002ee4 <bread>
    80003b40:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b42:	3ff97713          	andi	a4,s2,1023
    80003b46:	40ed07bb          	subw	a5,s10,a4
    80003b4a:	414b86bb          	subw	a3,s7,s4
    80003b4e:	89be                	mv	s3,a5
    80003b50:	2781                	sext.w	a5,a5
    80003b52:	0006861b          	sext.w	a2,a3
    80003b56:	f8f674e3          	bgeu	a2,a5,80003ade <writei+0x4c>
    80003b5a:	89b6                	mv	s3,a3
    80003b5c:	b749                	j	80003ade <writei+0x4c>
      brelse(bp);
    80003b5e:	8526                	mv	a0,s1
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	4b4080e7          	jalr	1204(ra) # 80003014 <brelse>
  }

  if(off > ip->size)
    80003b68:	04cb2783          	lw	a5,76(s6)
    80003b6c:	0127f463          	bgeu	a5,s2,80003b74 <writei+0xe2>
    ip->size = off;
    80003b70:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b74:	855a                	mv	a0,s6
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	aa6080e7          	jalr	-1370(ra) # 8000361c <iupdate>

  return tot;
    80003b7e:	000a051b          	sext.w	a0,s4
}
    80003b82:	70a6                	ld	ra,104(sp)
    80003b84:	7406                	ld	s0,96(sp)
    80003b86:	64e6                	ld	s1,88(sp)
    80003b88:	6946                	ld	s2,80(sp)
    80003b8a:	69a6                	ld	s3,72(sp)
    80003b8c:	6a06                	ld	s4,64(sp)
    80003b8e:	7ae2                	ld	s5,56(sp)
    80003b90:	7b42                	ld	s6,48(sp)
    80003b92:	7ba2                	ld	s7,40(sp)
    80003b94:	7c02                	ld	s8,32(sp)
    80003b96:	6ce2                	ld	s9,24(sp)
    80003b98:	6d42                	ld	s10,16(sp)
    80003b9a:	6da2                	ld	s11,8(sp)
    80003b9c:	6165                	addi	sp,sp,112
    80003b9e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba0:	8a5e                	mv	s4,s7
    80003ba2:	bfc9                	j	80003b74 <writei+0xe2>
    return -1;
    80003ba4:	557d                	li	a0,-1
}
    80003ba6:	8082                	ret
    return -1;
    80003ba8:	557d                	li	a0,-1
    80003baa:	bfe1                	j	80003b82 <writei+0xf0>
    return -1;
    80003bac:	557d                	li	a0,-1
    80003bae:	bfd1                	j	80003b82 <writei+0xf0>

0000000080003bb0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bb0:	1141                	addi	sp,sp,-16
    80003bb2:	e406                	sd	ra,8(sp)
    80003bb4:	e022                	sd	s0,0(sp)
    80003bb6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bb8:	4639                	li	a2,14
    80003bba:	ffffd097          	auipc	ra,0xffffd
    80003bbe:	1fe080e7          	jalr	510(ra) # 80000db8 <strncmp>
}
    80003bc2:	60a2                	ld	ra,8(sp)
    80003bc4:	6402                	ld	s0,0(sp)
    80003bc6:	0141                	addi	sp,sp,16
    80003bc8:	8082                	ret

0000000080003bca <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bca:	7139                	addi	sp,sp,-64
    80003bcc:	fc06                	sd	ra,56(sp)
    80003bce:	f822                	sd	s0,48(sp)
    80003bd0:	f426                	sd	s1,40(sp)
    80003bd2:	f04a                	sd	s2,32(sp)
    80003bd4:	ec4e                	sd	s3,24(sp)
    80003bd6:	e852                	sd	s4,16(sp)
    80003bd8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bda:	04451703          	lh	a4,68(a0)
    80003bde:	4785                	li	a5,1
    80003be0:	00f71a63          	bne	a4,a5,80003bf4 <dirlookup+0x2a>
    80003be4:	892a                	mv	s2,a0
    80003be6:	89ae                	mv	s3,a1
    80003be8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bea:	457c                	lw	a5,76(a0)
    80003bec:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bee:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bf0:	e79d                	bnez	a5,80003c1e <dirlookup+0x54>
    80003bf2:	a8a5                	j	80003c6a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bf4:	00005517          	auipc	a0,0x5
    80003bf8:	a9450513          	addi	a0,a0,-1388 # 80008688 <syscalls+0x1c0>
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	942080e7          	jalr	-1726(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c04:	00005517          	auipc	a0,0x5
    80003c08:	a9c50513          	addi	a0,a0,-1380 # 800086a0 <syscalls+0x1d8>
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	932080e7          	jalr	-1742(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c14:	24c1                	addiw	s1,s1,16
    80003c16:	04c92783          	lw	a5,76(s2)
    80003c1a:	04f4f763          	bgeu	s1,a5,80003c68 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c1e:	4741                	li	a4,16
    80003c20:	86a6                	mv	a3,s1
    80003c22:	fc040613          	addi	a2,s0,-64
    80003c26:	4581                	li	a1,0
    80003c28:	854a                	mv	a0,s2
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	d70080e7          	jalr	-656(ra) # 8000399a <readi>
    80003c32:	47c1                	li	a5,16
    80003c34:	fcf518e3          	bne	a0,a5,80003c04 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c38:	fc045783          	lhu	a5,-64(s0)
    80003c3c:	dfe1                	beqz	a5,80003c14 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c3e:	fc240593          	addi	a1,s0,-62
    80003c42:	854e                	mv	a0,s3
    80003c44:	00000097          	auipc	ra,0x0
    80003c48:	f6c080e7          	jalr	-148(ra) # 80003bb0 <namecmp>
    80003c4c:	f561                	bnez	a0,80003c14 <dirlookup+0x4a>
      if(poff)
    80003c4e:	000a0463          	beqz	s4,80003c56 <dirlookup+0x8c>
        *poff = off;
    80003c52:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c56:	fc045583          	lhu	a1,-64(s0)
    80003c5a:	00092503          	lw	a0,0(s2)
    80003c5e:	fffff097          	auipc	ra,0xfffff
    80003c62:	754080e7          	jalr	1876(ra) # 800033b2 <iget>
    80003c66:	a011                	j	80003c6a <dirlookup+0xa0>
  return 0;
    80003c68:	4501                	li	a0,0
}
    80003c6a:	70e2                	ld	ra,56(sp)
    80003c6c:	7442                	ld	s0,48(sp)
    80003c6e:	74a2                	ld	s1,40(sp)
    80003c70:	7902                	ld	s2,32(sp)
    80003c72:	69e2                	ld	s3,24(sp)
    80003c74:	6a42                	ld	s4,16(sp)
    80003c76:	6121                	addi	sp,sp,64
    80003c78:	8082                	ret

0000000080003c7a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c7a:	711d                	addi	sp,sp,-96
    80003c7c:	ec86                	sd	ra,88(sp)
    80003c7e:	e8a2                	sd	s0,80(sp)
    80003c80:	e4a6                	sd	s1,72(sp)
    80003c82:	e0ca                	sd	s2,64(sp)
    80003c84:	fc4e                	sd	s3,56(sp)
    80003c86:	f852                	sd	s4,48(sp)
    80003c88:	f456                	sd	s5,40(sp)
    80003c8a:	f05a                	sd	s6,32(sp)
    80003c8c:	ec5e                	sd	s7,24(sp)
    80003c8e:	e862                	sd	s8,16(sp)
    80003c90:	e466                	sd	s9,8(sp)
    80003c92:	1080                	addi	s0,sp,96
    80003c94:	84aa                	mv	s1,a0
    80003c96:	8b2e                	mv	s6,a1
    80003c98:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c9a:	00054703          	lbu	a4,0(a0)
    80003c9e:	02f00793          	li	a5,47
    80003ca2:	02f70363          	beq	a4,a5,80003cc8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ca6:	ffffe097          	auipc	ra,0xffffe
    80003caa:	d80080e7          	jalr	-640(ra) # 80001a26 <myproc>
    80003cae:	15053503          	ld	a0,336(a0)
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	9f6080e7          	jalr	-1546(ra) # 800036a8 <idup>
    80003cba:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cbc:	02f00913          	li	s2,47
  len = path - s;
    80003cc0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003cc2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cc4:	4c05                	li	s8,1
    80003cc6:	a865                	j	80003d7e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cc8:	4585                	li	a1,1
    80003cca:	4505                	li	a0,1
    80003ccc:	fffff097          	auipc	ra,0xfffff
    80003cd0:	6e6080e7          	jalr	1766(ra) # 800033b2 <iget>
    80003cd4:	89aa                	mv	s3,a0
    80003cd6:	b7dd                	j	80003cbc <namex+0x42>
      iunlockput(ip);
    80003cd8:	854e                	mv	a0,s3
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	c6e080e7          	jalr	-914(ra) # 80003948 <iunlockput>
      return 0;
    80003ce2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ce4:	854e                	mv	a0,s3
    80003ce6:	60e6                	ld	ra,88(sp)
    80003ce8:	6446                	ld	s0,80(sp)
    80003cea:	64a6                	ld	s1,72(sp)
    80003cec:	6906                	ld	s2,64(sp)
    80003cee:	79e2                	ld	s3,56(sp)
    80003cf0:	7a42                	ld	s4,48(sp)
    80003cf2:	7aa2                	ld	s5,40(sp)
    80003cf4:	7b02                	ld	s6,32(sp)
    80003cf6:	6be2                	ld	s7,24(sp)
    80003cf8:	6c42                	ld	s8,16(sp)
    80003cfa:	6ca2                	ld	s9,8(sp)
    80003cfc:	6125                	addi	sp,sp,96
    80003cfe:	8082                	ret
      iunlock(ip);
    80003d00:	854e                	mv	a0,s3
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	aa6080e7          	jalr	-1370(ra) # 800037a8 <iunlock>
      return ip;
    80003d0a:	bfe9                	j	80003ce4 <namex+0x6a>
      iunlockput(ip);
    80003d0c:	854e                	mv	a0,s3
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	c3a080e7          	jalr	-966(ra) # 80003948 <iunlockput>
      return 0;
    80003d16:	89d2                	mv	s3,s4
    80003d18:	b7f1                	j	80003ce4 <namex+0x6a>
  len = path - s;
    80003d1a:	40b48633          	sub	a2,s1,a1
    80003d1e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d22:	094cd463          	bge	s9,s4,80003daa <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d26:	4639                	li	a2,14
    80003d28:	8556                	mv	a0,s5
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	016080e7          	jalr	22(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003d32:	0004c783          	lbu	a5,0(s1)
    80003d36:	01279763          	bne	a5,s2,80003d44 <namex+0xca>
    path++;
    80003d3a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d3c:	0004c783          	lbu	a5,0(s1)
    80003d40:	ff278de3          	beq	a5,s2,80003d3a <namex+0xc0>
    ilock(ip);
    80003d44:	854e                	mv	a0,s3
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	9a0080e7          	jalr	-1632(ra) # 800036e6 <ilock>
    if(ip->type != T_DIR){
    80003d4e:	04499783          	lh	a5,68(s3)
    80003d52:	f98793e3          	bne	a5,s8,80003cd8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d56:	000b0563          	beqz	s6,80003d60 <namex+0xe6>
    80003d5a:	0004c783          	lbu	a5,0(s1)
    80003d5e:	d3cd                	beqz	a5,80003d00 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d60:	865e                	mv	a2,s7
    80003d62:	85d6                	mv	a1,s5
    80003d64:	854e                	mv	a0,s3
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	e64080e7          	jalr	-412(ra) # 80003bca <dirlookup>
    80003d6e:	8a2a                	mv	s4,a0
    80003d70:	dd51                	beqz	a0,80003d0c <namex+0x92>
    iunlockput(ip);
    80003d72:	854e                	mv	a0,s3
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	bd4080e7          	jalr	-1068(ra) # 80003948 <iunlockput>
    ip = next;
    80003d7c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d7e:	0004c783          	lbu	a5,0(s1)
    80003d82:	05279763          	bne	a5,s2,80003dd0 <namex+0x156>
    path++;
    80003d86:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d88:	0004c783          	lbu	a5,0(s1)
    80003d8c:	ff278de3          	beq	a5,s2,80003d86 <namex+0x10c>
  if(*path == 0)
    80003d90:	c79d                	beqz	a5,80003dbe <namex+0x144>
    path++;
    80003d92:	85a6                	mv	a1,s1
  len = path - s;
    80003d94:	8a5e                	mv	s4,s7
    80003d96:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d98:	01278963          	beq	a5,s2,80003daa <namex+0x130>
    80003d9c:	dfbd                	beqz	a5,80003d1a <namex+0xa0>
    path++;
    80003d9e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003da0:	0004c783          	lbu	a5,0(s1)
    80003da4:	ff279ce3          	bne	a5,s2,80003d9c <namex+0x122>
    80003da8:	bf8d                	j	80003d1a <namex+0xa0>
    memmove(name, s, len);
    80003daa:	2601                	sext.w	a2,a2
    80003dac:	8556                	mv	a0,s5
    80003dae:	ffffd097          	auipc	ra,0xffffd
    80003db2:	f92080e7          	jalr	-110(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003db6:	9a56                	add	s4,s4,s5
    80003db8:	000a0023          	sb	zero,0(s4)
    80003dbc:	bf9d                	j	80003d32 <namex+0xb8>
  if(nameiparent){
    80003dbe:	f20b03e3          	beqz	s6,80003ce4 <namex+0x6a>
    iput(ip);
    80003dc2:	854e                	mv	a0,s3
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	adc080e7          	jalr	-1316(ra) # 800038a0 <iput>
    return 0;
    80003dcc:	4981                	li	s3,0
    80003dce:	bf19                	j	80003ce4 <namex+0x6a>
  if(*path == 0)
    80003dd0:	d7fd                	beqz	a5,80003dbe <namex+0x144>
  while(*path != '/' && *path != 0)
    80003dd2:	0004c783          	lbu	a5,0(s1)
    80003dd6:	85a6                	mv	a1,s1
    80003dd8:	b7d1                	j	80003d9c <namex+0x122>

0000000080003dda <dirlink>:
{
    80003dda:	7139                	addi	sp,sp,-64
    80003ddc:	fc06                	sd	ra,56(sp)
    80003dde:	f822                	sd	s0,48(sp)
    80003de0:	f426                	sd	s1,40(sp)
    80003de2:	f04a                	sd	s2,32(sp)
    80003de4:	ec4e                	sd	s3,24(sp)
    80003de6:	e852                	sd	s4,16(sp)
    80003de8:	0080                	addi	s0,sp,64
    80003dea:	892a                	mv	s2,a0
    80003dec:	8a2e                	mv	s4,a1
    80003dee:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003df0:	4601                	li	a2,0
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	dd8080e7          	jalr	-552(ra) # 80003bca <dirlookup>
    80003dfa:	e93d                	bnez	a0,80003e70 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfc:	04c92483          	lw	s1,76(s2)
    80003e00:	c49d                	beqz	s1,80003e2e <dirlink+0x54>
    80003e02:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e04:	4741                	li	a4,16
    80003e06:	86a6                	mv	a3,s1
    80003e08:	fc040613          	addi	a2,s0,-64
    80003e0c:	4581                	li	a1,0
    80003e0e:	854a                	mv	a0,s2
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	b8a080e7          	jalr	-1142(ra) # 8000399a <readi>
    80003e18:	47c1                	li	a5,16
    80003e1a:	06f51163          	bne	a0,a5,80003e7c <dirlink+0xa2>
    if(de.inum == 0)
    80003e1e:	fc045783          	lhu	a5,-64(s0)
    80003e22:	c791                	beqz	a5,80003e2e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e24:	24c1                	addiw	s1,s1,16
    80003e26:	04c92783          	lw	a5,76(s2)
    80003e2a:	fcf4ede3          	bltu	s1,a5,80003e04 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e2e:	4639                	li	a2,14
    80003e30:	85d2                	mv	a1,s4
    80003e32:	fc240513          	addi	a0,s0,-62
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	fbe080e7          	jalr	-66(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003e3e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e42:	4741                	li	a4,16
    80003e44:	86a6                	mv	a3,s1
    80003e46:	fc040613          	addi	a2,s0,-64
    80003e4a:	4581                	li	a1,0
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	c44080e7          	jalr	-956(ra) # 80003a92 <writei>
    80003e56:	872a                	mv	a4,a0
    80003e58:	47c1                	li	a5,16
  return 0;
    80003e5a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e5c:	02f71863          	bne	a4,a5,80003e8c <dirlink+0xb2>
}
    80003e60:	70e2                	ld	ra,56(sp)
    80003e62:	7442                	ld	s0,48(sp)
    80003e64:	74a2                	ld	s1,40(sp)
    80003e66:	7902                	ld	s2,32(sp)
    80003e68:	69e2                	ld	s3,24(sp)
    80003e6a:	6a42                	ld	s4,16(sp)
    80003e6c:	6121                	addi	sp,sp,64
    80003e6e:	8082                	ret
    iput(ip);
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	a30080e7          	jalr	-1488(ra) # 800038a0 <iput>
    return -1;
    80003e78:	557d                	li	a0,-1
    80003e7a:	b7dd                	j	80003e60 <dirlink+0x86>
      panic("dirlink read");
    80003e7c:	00005517          	auipc	a0,0x5
    80003e80:	83450513          	addi	a0,a0,-1996 # 800086b0 <syscalls+0x1e8>
    80003e84:	ffffc097          	auipc	ra,0xffffc
    80003e88:	6ba080e7          	jalr	1722(ra) # 8000053e <panic>
    panic("dirlink");
    80003e8c:	00005517          	auipc	a0,0x5
    80003e90:	93450513          	addi	a0,a0,-1740 # 800087c0 <syscalls+0x2f8>
    80003e94:	ffffc097          	auipc	ra,0xffffc
    80003e98:	6aa080e7          	jalr	1706(ra) # 8000053e <panic>

0000000080003e9c <namei>:

struct inode*
namei(char *path)
{
    80003e9c:	1101                	addi	sp,sp,-32
    80003e9e:	ec06                	sd	ra,24(sp)
    80003ea0:	e822                	sd	s0,16(sp)
    80003ea2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ea4:	fe040613          	addi	a2,s0,-32
    80003ea8:	4581                	li	a1,0
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	dd0080e7          	jalr	-560(ra) # 80003c7a <namex>
}
    80003eb2:	60e2                	ld	ra,24(sp)
    80003eb4:	6442                	ld	s0,16(sp)
    80003eb6:	6105                	addi	sp,sp,32
    80003eb8:	8082                	ret

0000000080003eba <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003eba:	1141                	addi	sp,sp,-16
    80003ebc:	e406                	sd	ra,8(sp)
    80003ebe:	e022                	sd	s0,0(sp)
    80003ec0:	0800                	addi	s0,sp,16
    80003ec2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ec4:	4585                	li	a1,1
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	db4080e7          	jalr	-588(ra) # 80003c7a <namex>
}
    80003ece:	60a2                	ld	ra,8(sp)
    80003ed0:	6402                	ld	s0,0(sp)
    80003ed2:	0141                	addi	sp,sp,16
    80003ed4:	8082                	ret

0000000080003ed6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ed6:	1101                	addi	sp,sp,-32
    80003ed8:	ec06                	sd	ra,24(sp)
    80003eda:	e822                	sd	s0,16(sp)
    80003edc:	e426                	sd	s1,8(sp)
    80003ede:	e04a                	sd	s2,0(sp)
    80003ee0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ee2:	0001d917          	auipc	s2,0x1d
    80003ee6:	58e90913          	addi	s2,s2,1422 # 80021470 <log>
    80003eea:	01892583          	lw	a1,24(s2)
    80003eee:	02892503          	lw	a0,40(s2)
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	ff2080e7          	jalr	-14(ra) # 80002ee4 <bread>
    80003efa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003efc:	02c92683          	lw	a3,44(s2)
    80003f00:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f02:	02d05763          	blez	a3,80003f30 <write_head+0x5a>
    80003f06:	0001d797          	auipc	a5,0x1d
    80003f0a:	59a78793          	addi	a5,a5,1434 # 800214a0 <log+0x30>
    80003f0e:	05c50713          	addi	a4,a0,92
    80003f12:	36fd                	addiw	a3,a3,-1
    80003f14:	1682                	slli	a3,a3,0x20
    80003f16:	9281                	srli	a3,a3,0x20
    80003f18:	068a                	slli	a3,a3,0x2
    80003f1a:	0001d617          	auipc	a2,0x1d
    80003f1e:	58a60613          	addi	a2,a2,1418 # 800214a4 <log+0x34>
    80003f22:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f24:	4390                	lw	a2,0(a5)
    80003f26:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f28:	0791                	addi	a5,a5,4
    80003f2a:	0711                	addi	a4,a4,4
    80003f2c:	fed79ce3          	bne	a5,a3,80003f24 <write_head+0x4e>
  }
  bwrite(buf);
    80003f30:	8526                	mv	a0,s1
    80003f32:	fffff097          	auipc	ra,0xfffff
    80003f36:	0a4080e7          	jalr	164(ra) # 80002fd6 <bwrite>
  brelse(buf);
    80003f3a:	8526                	mv	a0,s1
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	0d8080e7          	jalr	216(ra) # 80003014 <brelse>
}
    80003f44:	60e2                	ld	ra,24(sp)
    80003f46:	6442                	ld	s0,16(sp)
    80003f48:	64a2                	ld	s1,8(sp)
    80003f4a:	6902                	ld	s2,0(sp)
    80003f4c:	6105                	addi	sp,sp,32
    80003f4e:	8082                	ret

0000000080003f50 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f50:	0001d797          	auipc	a5,0x1d
    80003f54:	54c7a783          	lw	a5,1356(a5) # 8002149c <log+0x2c>
    80003f58:	0af05d63          	blez	a5,80004012 <install_trans+0xc2>
{
    80003f5c:	7139                	addi	sp,sp,-64
    80003f5e:	fc06                	sd	ra,56(sp)
    80003f60:	f822                	sd	s0,48(sp)
    80003f62:	f426                	sd	s1,40(sp)
    80003f64:	f04a                	sd	s2,32(sp)
    80003f66:	ec4e                	sd	s3,24(sp)
    80003f68:	e852                	sd	s4,16(sp)
    80003f6a:	e456                	sd	s5,8(sp)
    80003f6c:	e05a                	sd	s6,0(sp)
    80003f6e:	0080                	addi	s0,sp,64
    80003f70:	8b2a                	mv	s6,a0
    80003f72:	0001da97          	auipc	s5,0x1d
    80003f76:	52ea8a93          	addi	s5,s5,1326 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f7a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f7c:	0001d997          	auipc	s3,0x1d
    80003f80:	4f498993          	addi	s3,s3,1268 # 80021470 <log>
    80003f84:	a035                	j	80003fb0 <install_trans+0x60>
      bunpin(dbuf);
    80003f86:	8526                	mv	a0,s1
    80003f88:	fffff097          	auipc	ra,0xfffff
    80003f8c:	166080e7          	jalr	358(ra) # 800030ee <bunpin>
    brelse(lbuf);
    80003f90:	854a                	mv	a0,s2
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	082080e7          	jalr	130(ra) # 80003014 <brelse>
    brelse(dbuf);
    80003f9a:	8526                	mv	a0,s1
    80003f9c:	fffff097          	auipc	ra,0xfffff
    80003fa0:	078080e7          	jalr	120(ra) # 80003014 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa4:	2a05                	addiw	s4,s4,1
    80003fa6:	0a91                	addi	s5,s5,4
    80003fa8:	02c9a783          	lw	a5,44(s3)
    80003fac:	04fa5963          	bge	s4,a5,80003ffe <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fb0:	0189a583          	lw	a1,24(s3)
    80003fb4:	014585bb          	addw	a1,a1,s4
    80003fb8:	2585                	addiw	a1,a1,1
    80003fba:	0289a503          	lw	a0,40(s3)
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	f26080e7          	jalr	-218(ra) # 80002ee4 <bread>
    80003fc6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fc8:	000aa583          	lw	a1,0(s5)
    80003fcc:	0289a503          	lw	a0,40(s3)
    80003fd0:	fffff097          	auipc	ra,0xfffff
    80003fd4:	f14080e7          	jalr	-236(ra) # 80002ee4 <bread>
    80003fd8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fda:	40000613          	li	a2,1024
    80003fde:	05890593          	addi	a1,s2,88
    80003fe2:	05850513          	addi	a0,a0,88
    80003fe6:	ffffd097          	auipc	ra,0xffffd
    80003fea:	d5a080e7          	jalr	-678(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fee:	8526                	mv	a0,s1
    80003ff0:	fffff097          	auipc	ra,0xfffff
    80003ff4:	fe6080e7          	jalr	-26(ra) # 80002fd6 <bwrite>
    if(recovering == 0)
    80003ff8:	f80b1ce3          	bnez	s6,80003f90 <install_trans+0x40>
    80003ffc:	b769                	j	80003f86 <install_trans+0x36>
}
    80003ffe:	70e2                	ld	ra,56(sp)
    80004000:	7442                	ld	s0,48(sp)
    80004002:	74a2                	ld	s1,40(sp)
    80004004:	7902                	ld	s2,32(sp)
    80004006:	69e2                	ld	s3,24(sp)
    80004008:	6a42                	ld	s4,16(sp)
    8000400a:	6aa2                	ld	s5,8(sp)
    8000400c:	6b02                	ld	s6,0(sp)
    8000400e:	6121                	addi	sp,sp,64
    80004010:	8082                	ret
    80004012:	8082                	ret

0000000080004014 <initlog>:
{
    80004014:	7179                	addi	sp,sp,-48
    80004016:	f406                	sd	ra,40(sp)
    80004018:	f022                	sd	s0,32(sp)
    8000401a:	ec26                	sd	s1,24(sp)
    8000401c:	e84a                	sd	s2,16(sp)
    8000401e:	e44e                	sd	s3,8(sp)
    80004020:	1800                	addi	s0,sp,48
    80004022:	892a                	mv	s2,a0
    80004024:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004026:	0001d497          	auipc	s1,0x1d
    8000402a:	44a48493          	addi	s1,s1,1098 # 80021470 <log>
    8000402e:	00004597          	auipc	a1,0x4
    80004032:	69258593          	addi	a1,a1,1682 # 800086c0 <syscalls+0x1f8>
    80004036:	8526                	mv	a0,s1
    80004038:	ffffd097          	auipc	ra,0xffffd
    8000403c:	b1c080e7          	jalr	-1252(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004040:	0149a583          	lw	a1,20(s3)
    80004044:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004046:	0109a783          	lw	a5,16(s3)
    8000404a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000404c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004050:	854a                	mv	a0,s2
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	e92080e7          	jalr	-366(ra) # 80002ee4 <bread>
  log.lh.n = lh->n;
    8000405a:	4d3c                	lw	a5,88(a0)
    8000405c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000405e:	02f05563          	blez	a5,80004088 <initlog+0x74>
    80004062:	05c50713          	addi	a4,a0,92
    80004066:	0001d697          	auipc	a3,0x1d
    8000406a:	43a68693          	addi	a3,a3,1082 # 800214a0 <log+0x30>
    8000406e:	37fd                	addiw	a5,a5,-1
    80004070:	1782                	slli	a5,a5,0x20
    80004072:	9381                	srli	a5,a5,0x20
    80004074:	078a                	slli	a5,a5,0x2
    80004076:	06050613          	addi	a2,a0,96
    8000407a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000407c:	4310                	lw	a2,0(a4)
    8000407e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004080:	0711                	addi	a4,a4,4
    80004082:	0691                	addi	a3,a3,4
    80004084:	fef71ce3          	bne	a4,a5,8000407c <initlog+0x68>
  brelse(buf);
    80004088:	fffff097          	auipc	ra,0xfffff
    8000408c:	f8c080e7          	jalr	-116(ra) # 80003014 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004090:	4505                	li	a0,1
    80004092:	00000097          	auipc	ra,0x0
    80004096:	ebe080e7          	jalr	-322(ra) # 80003f50 <install_trans>
  log.lh.n = 0;
    8000409a:	0001d797          	auipc	a5,0x1d
    8000409e:	4007a123          	sw	zero,1026(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	e34080e7          	jalr	-460(ra) # 80003ed6 <write_head>
}
    800040aa:	70a2                	ld	ra,40(sp)
    800040ac:	7402                	ld	s0,32(sp)
    800040ae:	64e2                	ld	s1,24(sp)
    800040b0:	6942                	ld	s2,16(sp)
    800040b2:	69a2                	ld	s3,8(sp)
    800040b4:	6145                	addi	sp,sp,48
    800040b6:	8082                	ret

00000000800040b8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040b8:	1101                	addi	sp,sp,-32
    800040ba:	ec06                	sd	ra,24(sp)
    800040bc:	e822                	sd	s0,16(sp)
    800040be:	e426                	sd	s1,8(sp)
    800040c0:	e04a                	sd	s2,0(sp)
    800040c2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040c4:	0001d517          	auipc	a0,0x1d
    800040c8:	3ac50513          	addi	a0,a0,940 # 80021470 <log>
    800040cc:	ffffd097          	auipc	ra,0xffffd
    800040d0:	b18080e7          	jalr	-1256(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800040d4:	0001d497          	auipc	s1,0x1d
    800040d8:	39c48493          	addi	s1,s1,924 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040dc:	4979                	li	s2,30
    800040de:	a039                	j	800040ec <begin_op+0x34>
      sleep(&log, &log.lock);
    800040e0:	85a6                	mv	a1,s1
    800040e2:	8526                	mv	a0,s1
    800040e4:	ffffe097          	auipc	ra,0xffffe
    800040e8:	02e080e7          	jalr	46(ra) # 80002112 <sleep>
    if(log.committing){
    800040ec:	50dc                	lw	a5,36(s1)
    800040ee:	fbed                	bnez	a5,800040e0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040f0:	509c                	lw	a5,32(s1)
    800040f2:	0017871b          	addiw	a4,a5,1
    800040f6:	0007069b          	sext.w	a3,a4
    800040fa:	0027179b          	slliw	a5,a4,0x2
    800040fe:	9fb9                	addw	a5,a5,a4
    80004100:	0017979b          	slliw	a5,a5,0x1
    80004104:	54d8                	lw	a4,44(s1)
    80004106:	9fb9                	addw	a5,a5,a4
    80004108:	00f95963          	bge	s2,a5,8000411a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000410c:	85a6                	mv	a1,s1
    8000410e:	8526                	mv	a0,s1
    80004110:	ffffe097          	auipc	ra,0xffffe
    80004114:	002080e7          	jalr	2(ra) # 80002112 <sleep>
    80004118:	bfd1                	j	800040ec <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000411a:	0001d517          	auipc	a0,0x1d
    8000411e:	35650513          	addi	a0,a0,854 # 80021470 <log>
    80004122:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004124:	ffffd097          	auipc	ra,0xffffd
    80004128:	b74080e7          	jalr	-1164(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000412c:	60e2                	ld	ra,24(sp)
    8000412e:	6442                	ld	s0,16(sp)
    80004130:	64a2                	ld	s1,8(sp)
    80004132:	6902                	ld	s2,0(sp)
    80004134:	6105                	addi	sp,sp,32
    80004136:	8082                	ret

0000000080004138 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004138:	7139                	addi	sp,sp,-64
    8000413a:	fc06                	sd	ra,56(sp)
    8000413c:	f822                	sd	s0,48(sp)
    8000413e:	f426                	sd	s1,40(sp)
    80004140:	f04a                	sd	s2,32(sp)
    80004142:	ec4e                	sd	s3,24(sp)
    80004144:	e852                	sd	s4,16(sp)
    80004146:	e456                	sd	s5,8(sp)
    80004148:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000414a:	0001d497          	auipc	s1,0x1d
    8000414e:	32648493          	addi	s1,s1,806 # 80021470 <log>
    80004152:	8526                	mv	a0,s1
    80004154:	ffffd097          	auipc	ra,0xffffd
    80004158:	a90080e7          	jalr	-1392(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000415c:	509c                	lw	a5,32(s1)
    8000415e:	37fd                	addiw	a5,a5,-1
    80004160:	0007891b          	sext.w	s2,a5
    80004164:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004166:	50dc                	lw	a5,36(s1)
    80004168:	efb9                	bnez	a5,800041c6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000416a:	06091663          	bnez	s2,800041d6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000416e:	0001d497          	auipc	s1,0x1d
    80004172:	30248493          	addi	s1,s1,770 # 80021470 <log>
    80004176:	4785                	li	a5,1
    80004178:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000417a:	8526                	mv	a0,s1
    8000417c:	ffffd097          	auipc	ra,0xffffd
    80004180:	b1c080e7          	jalr	-1252(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004184:	54dc                	lw	a5,44(s1)
    80004186:	06f04763          	bgtz	a5,800041f4 <end_op+0xbc>
    acquire(&log.lock);
    8000418a:	0001d497          	auipc	s1,0x1d
    8000418e:	2e648493          	addi	s1,s1,742 # 80021470 <log>
    80004192:	8526                	mv	a0,s1
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000419c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041a0:	8526                	mv	a0,s1
    800041a2:	ffffe097          	auipc	ra,0xffffe
    800041a6:	0fc080e7          	jalr	252(ra) # 8000229e <wakeup>
    release(&log.lock);
    800041aa:	8526                	mv	a0,s1
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	aec080e7          	jalr	-1300(ra) # 80000c98 <release>
}
    800041b4:	70e2                	ld	ra,56(sp)
    800041b6:	7442                	ld	s0,48(sp)
    800041b8:	74a2                	ld	s1,40(sp)
    800041ba:	7902                	ld	s2,32(sp)
    800041bc:	69e2                	ld	s3,24(sp)
    800041be:	6a42                	ld	s4,16(sp)
    800041c0:	6aa2                	ld	s5,8(sp)
    800041c2:	6121                	addi	sp,sp,64
    800041c4:	8082                	ret
    panic("log.committing");
    800041c6:	00004517          	auipc	a0,0x4
    800041ca:	50250513          	addi	a0,a0,1282 # 800086c8 <syscalls+0x200>
    800041ce:	ffffc097          	auipc	ra,0xffffc
    800041d2:	370080e7          	jalr	880(ra) # 8000053e <panic>
    wakeup(&log);
    800041d6:	0001d497          	auipc	s1,0x1d
    800041da:	29a48493          	addi	s1,s1,666 # 80021470 <log>
    800041de:	8526                	mv	a0,s1
    800041e0:	ffffe097          	auipc	ra,0xffffe
    800041e4:	0be080e7          	jalr	190(ra) # 8000229e <wakeup>
  release(&log.lock);
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
  if(do_commit){
    800041f2:	b7c9                	j	800041b4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f4:	0001da97          	auipc	s5,0x1d
    800041f8:	2aca8a93          	addi	s5,s5,684 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041fc:	0001da17          	auipc	s4,0x1d
    80004200:	274a0a13          	addi	s4,s4,628 # 80021470 <log>
    80004204:	018a2583          	lw	a1,24(s4)
    80004208:	012585bb          	addw	a1,a1,s2
    8000420c:	2585                	addiw	a1,a1,1
    8000420e:	028a2503          	lw	a0,40(s4)
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	cd2080e7          	jalr	-814(ra) # 80002ee4 <bread>
    8000421a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000421c:	000aa583          	lw	a1,0(s5)
    80004220:	028a2503          	lw	a0,40(s4)
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	cc0080e7          	jalr	-832(ra) # 80002ee4 <bread>
    8000422c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000422e:	40000613          	li	a2,1024
    80004232:	05850593          	addi	a1,a0,88
    80004236:	05848513          	addi	a0,s1,88
    8000423a:	ffffd097          	auipc	ra,0xffffd
    8000423e:	b06080e7          	jalr	-1274(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004242:	8526                	mv	a0,s1
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	d92080e7          	jalr	-622(ra) # 80002fd6 <bwrite>
    brelse(from);
    8000424c:	854e                	mv	a0,s3
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	dc6080e7          	jalr	-570(ra) # 80003014 <brelse>
    brelse(to);
    80004256:	8526                	mv	a0,s1
    80004258:	fffff097          	auipc	ra,0xfffff
    8000425c:	dbc080e7          	jalr	-580(ra) # 80003014 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004260:	2905                	addiw	s2,s2,1
    80004262:	0a91                	addi	s5,s5,4
    80004264:	02ca2783          	lw	a5,44(s4)
    80004268:	f8f94ee3          	blt	s2,a5,80004204 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000426c:	00000097          	auipc	ra,0x0
    80004270:	c6a080e7          	jalr	-918(ra) # 80003ed6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004274:	4501                	li	a0,0
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	cda080e7          	jalr	-806(ra) # 80003f50 <install_trans>
    log.lh.n = 0;
    8000427e:	0001d797          	auipc	a5,0x1d
    80004282:	2007af23          	sw	zero,542(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	c50080e7          	jalr	-944(ra) # 80003ed6 <write_head>
    8000428e:	bdf5                	j	8000418a <end_op+0x52>

0000000080004290 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004290:	1101                	addi	sp,sp,-32
    80004292:	ec06                	sd	ra,24(sp)
    80004294:	e822                	sd	s0,16(sp)
    80004296:	e426                	sd	s1,8(sp)
    80004298:	e04a                	sd	s2,0(sp)
    8000429a:	1000                	addi	s0,sp,32
    8000429c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000429e:	0001d917          	auipc	s2,0x1d
    800042a2:	1d290913          	addi	s2,s2,466 # 80021470 <log>
    800042a6:	854a                	mv	a0,s2
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	93c080e7          	jalr	-1732(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042b0:	02c92603          	lw	a2,44(s2)
    800042b4:	47f5                	li	a5,29
    800042b6:	06c7c563          	blt	a5,a2,80004320 <log_write+0x90>
    800042ba:	0001d797          	auipc	a5,0x1d
    800042be:	1d27a783          	lw	a5,466(a5) # 8002148c <log+0x1c>
    800042c2:	37fd                	addiw	a5,a5,-1
    800042c4:	04f65e63          	bge	a2,a5,80004320 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042c8:	0001d797          	auipc	a5,0x1d
    800042cc:	1c87a783          	lw	a5,456(a5) # 80021490 <log+0x20>
    800042d0:	06f05063          	blez	a5,80004330 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042d4:	4781                	li	a5,0
    800042d6:	06c05563          	blez	a2,80004340 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042da:	44cc                	lw	a1,12(s1)
    800042dc:	0001d717          	auipc	a4,0x1d
    800042e0:	1c470713          	addi	a4,a4,452 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042e4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042e6:	4314                	lw	a3,0(a4)
    800042e8:	04b68c63          	beq	a3,a1,80004340 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042ec:	2785                	addiw	a5,a5,1
    800042ee:	0711                	addi	a4,a4,4
    800042f0:	fef61be3          	bne	a2,a5,800042e6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042f4:	0621                	addi	a2,a2,8
    800042f6:	060a                	slli	a2,a2,0x2
    800042f8:	0001d797          	auipc	a5,0x1d
    800042fc:	17878793          	addi	a5,a5,376 # 80021470 <log>
    80004300:	963e                	add	a2,a2,a5
    80004302:	44dc                	lw	a5,12(s1)
    80004304:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004306:	8526                	mv	a0,s1
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	daa080e7          	jalr	-598(ra) # 800030b2 <bpin>
    log.lh.n++;
    80004310:	0001d717          	auipc	a4,0x1d
    80004314:	16070713          	addi	a4,a4,352 # 80021470 <log>
    80004318:	575c                	lw	a5,44(a4)
    8000431a:	2785                	addiw	a5,a5,1
    8000431c:	d75c                	sw	a5,44(a4)
    8000431e:	a835                	j	8000435a <log_write+0xca>
    panic("too big a transaction");
    80004320:	00004517          	auipc	a0,0x4
    80004324:	3b850513          	addi	a0,a0,952 # 800086d8 <syscalls+0x210>
    80004328:	ffffc097          	auipc	ra,0xffffc
    8000432c:	216080e7          	jalr	534(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004330:	00004517          	auipc	a0,0x4
    80004334:	3c050513          	addi	a0,a0,960 # 800086f0 <syscalls+0x228>
    80004338:	ffffc097          	auipc	ra,0xffffc
    8000433c:	206080e7          	jalr	518(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004340:	00878713          	addi	a4,a5,8
    80004344:	00271693          	slli	a3,a4,0x2
    80004348:	0001d717          	auipc	a4,0x1d
    8000434c:	12870713          	addi	a4,a4,296 # 80021470 <log>
    80004350:	9736                	add	a4,a4,a3
    80004352:	44d4                	lw	a3,12(s1)
    80004354:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004356:	faf608e3          	beq	a2,a5,80004306 <log_write+0x76>
  }
  release(&log.lock);
    8000435a:	0001d517          	auipc	a0,0x1d
    8000435e:	11650513          	addi	a0,a0,278 # 80021470 <log>
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	936080e7          	jalr	-1738(ra) # 80000c98 <release>
}
    8000436a:	60e2                	ld	ra,24(sp)
    8000436c:	6442                	ld	s0,16(sp)
    8000436e:	64a2                	ld	s1,8(sp)
    80004370:	6902                	ld	s2,0(sp)
    80004372:	6105                	addi	sp,sp,32
    80004374:	8082                	ret

0000000080004376 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004376:	1101                	addi	sp,sp,-32
    80004378:	ec06                	sd	ra,24(sp)
    8000437a:	e822                	sd	s0,16(sp)
    8000437c:	e426                	sd	s1,8(sp)
    8000437e:	e04a                	sd	s2,0(sp)
    80004380:	1000                	addi	s0,sp,32
    80004382:	84aa                	mv	s1,a0
    80004384:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004386:	00004597          	auipc	a1,0x4
    8000438a:	38a58593          	addi	a1,a1,906 # 80008710 <syscalls+0x248>
    8000438e:	0521                	addi	a0,a0,8
    80004390:	ffffc097          	auipc	ra,0xffffc
    80004394:	7c4080e7          	jalr	1988(ra) # 80000b54 <initlock>
  lk->name = name;
    80004398:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000439c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043a0:	0204a423          	sw	zero,40(s1)
}
    800043a4:	60e2                	ld	ra,24(sp)
    800043a6:	6442                	ld	s0,16(sp)
    800043a8:	64a2                	ld	s1,8(sp)
    800043aa:	6902                	ld	s2,0(sp)
    800043ac:	6105                	addi	sp,sp,32
    800043ae:	8082                	ret

00000000800043b0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043b0:	1101                	addi	sp,sp,-32
    800043b2:	ec06                	sd	ra,24(sp)
    800043b4:	e822                	sd	s0,16(sp)
    800043b6:	e426                	sd	s1,8(sp)
    800043b8:	e04a                	sd	s2,0(sp)
    800043ba:	1000                	addi	s0,sp,32
    800043bc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043be:	00850913          	addi	s2,a0,8
    800043c2:	854a                	mv	a0,s2
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	820080e7          	jalr	-2016(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800043cc:	409c                	lw	a5,0(s1)
    800043ce:	cb89                	beqz	a5,800043e0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043d0:	85ca                	mv	a1,s2
    800043d2:	8526                	mv	a0,s1
    800043d4:	ffffe097          	auipc	ra,0xffffe
    800043d8:	d3e080e7          	jalr	-706(ra) # 80002112 <sleep>
  while (lk->locked) {
    800043dc:	409c                	lw	a5,0(s1)
    800043de:	fbed                	bnez	a5,800043d0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043e0:	4785                	li	a5,1
    800043e2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043e4:	ffffd097          	auipc	ra,0xffffd
    800043e8:	642080e7          	jalr	1602(ra) # 80001a26 <myproc>
    800043ec:	591c                	lw	a5,48(a0)
    800043ee:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043f0:	854a                	mv	a0,s2
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
}
    800043fa:	60e2                	ld	ra,24(sp)
    800043fc:	6442                	ld	s0,16(sp)
    800043fe:	64a2                	ld	s1,8(sp)
    80004400:	6902                	ld	s2,0(sp)
    80004402:	6105                	addi	sp,sp,32
    80004404:	8082                	ret

0000000080004406 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004406:	1101                	addi	sp,sp,-32
    80004408:	ec06                	sd	ra,24(sp)
    8000440a:	e822                	sd	s0,16(sp)
    8000440c:	e426                	sd	s1,8(sp)
    8000440e:	e04a                	sd	s2,0(sp)
    80004410:	1000                	addi	s0,sp,32
    80004412:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004414:	00850913          	addi	s2,a0,8
    80004418:	854a                	mv	a0,s2
    8000441a:	ffffc097          	auipc	ra,0xffffc
    8000441e:	7ca080e7          	jalr	1994(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004422:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004426:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000442a:	8526                	mv	a0,s1
    8000442c:	ffffe097          	auipc	ra,0xffffe
    80004430:	e72080e7          	jalr	-398(ra) # 8000229e <wakeup>
  release(&lk->lk);
    80004434:	854a                	mv	a0,s2
    80004436:	ffffd097          	auipc	ra,0xffffd
    8000443a:	862080e7          	jalr	-1950(ra) # 80000c98 <release>
}
    8000443e:	60e2                	ld	ra,24(sp)
    80004440:	6442                	ld	s0,16(sp)
    80004442:	64a2                	ld	s1,8(sp)
    80004444:	6902                	ld	s2,0(sp)
    80004446:	6105                	addi	sp,sp,32
    80004448:	8082                	ret

000000008000444a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000444a:	7179                	addi	sp,sp,-48
    8000444c:	f406                	sd	ra,40(sp)
    8000444e:	f022                	sd	s0,32(sp)
    80004450:	ec26                	sd	s1,24(sp)
    80004452:	e84a                	sd	s2,16(sp)
    80004454:	e44e                	sd	s3,8(sp)
    80004456:	1800                	addi	s0,sp,48
    80004458:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000445a:	00850913          	addi	s2,a0,8
    8000445e:	854a                	mv	a0,s2
    80004460:	ffffc097          	auipc	ra,0xffffc
    80004464:	784080e7          	jalr	1924(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004468:	409c                	lw	a5,0(s1)
    8000446a:	ef99                	bnez	a5,80004488 <holdingsleep+0x3e>
    8000446c:	4481                	li	s1,0
  release(&lk->lk);
    8000446e:	854a                	mv	a0,s2
    80004470:	ffffd097          	auipc	ra,0xffffd
    80004474:	828080e7          	jalr	-2008(ra) # 80000c98 <release>
  return r;
}
    80004478:	8526                	mv	a0,s1
    8000447a:	70a2                	ld	ra,40(sp)
    8000447c:	7402                	ld	s0,32(sp)
    8000447e:	64e2                	ld	s1,24(sp)
    80004480:	6942                	ld	s2,16(sp)
    80004482:	69a2                	ld	s3,8(sp)
    80004484:	6145                	addi	sp,sp,48
    80004486:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004488:	0284a983          	lw	s3,40(s1)
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	59a080e7          	jalr	1434(ra) # 80001a26 <myproc>
    80004494:	5904                	lw	s1,48(a0)
    80004496:	413484b3          	sub	s1,s1,s3
    8000449a:	0014b493          	seqz	s1,s1
    8000449e:	bfc1                	j	8000446e <holdingsleep+0x24>

00000000800044a0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044a0:	1141                	addi	sp,sp,-16
    800044a2:	e406                	sd	ra,8(sp)
    800044a4:	e022                	sd	s0,0(sp)
    800044a6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044a8:	00004597          	auipc	a1,0x4
    800044ac:	27858593          	addi	a1,a1,632 # 80008720 <syscalls+0x258>
    800044b0:	0001d517          	auipc	a0,0x1d
    800044b4:	10850513          	addi	a0,a0,264 # 800215b8 <ftable>
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	69c080e7          	jalr	1692(ra) # 80000b54 <initlock>
}
    800044c0:	60a2                	ld	ra,8(sp)
    800044c2:	6402                	ld	s0,0(sp)
    800044c4:	0141                	addi	sp,sp,16
    800044c6:	8082                	ret

00000000800044c8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044c8:	1101                	addi	sp,sp,-32
    800044ca:	ec06                	sd	ra,24(sp)
    800044cc:	e822                	sd	s0,16(sp)
    800044ce:	e426                	sd	s1,8(sp)
    800044d0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044d2:	0001d517          	auipc	a0,0x1d
    800044d6:	0e650513          	addi	a0,a0,230 # 800215b8 <ftable>
    800044da:	ffffc097          	auipc	ra,0xffffc
    800044de:	70a080e7          	jalr	1802(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044e2:	0001d497          	auipc	s1,0x1d
    800044e6:	0ee48493          	addi	s1,s1,238 # 800215d0 <ftable+0x18>
    800044ea:	0001e717          	auipc	a4,0x1e
    800044ee:	08670713          	addi	a4,a4,134 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    800044f2:	40dc                	lw	a5,4(s1)
    800044f4:	cf99                	beqz	a5,80004512 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044f6:	02848493          	addi	s1,s1,40
    800044fa:	fee49ce3          	bne	s1,a4,800044f2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044fe:	0001d517          	auipc	a0,0x1d
    80004502:	0ba50513          	addi	a0,a0,186 # 800215b8 <ftable>
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	792080e7          	jalr	1938(ra) # 80000c98 <release>
  return 0;
    8000450e:	4481                	li	s1,0
    80004510:	a819                	j	80004526 <filealloc+0x5e>
      f->ref = 1;
    80004512:	4785                	li	a5,1
    80004514:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004516:	0001d517          	auipc	a0,0x1d
    8000451a:	0a250513          	addi	a0,a0,162 # 800215b8 <ftable>
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	77a080e7          	jalr	1914(ra) # 80000c98 <release>
}
    80004526:	8526                	mv	a0,s1
    80004528:	60e2                	ld	ra,24(sp)
    8000452a:	6442                	ld	s0,16(sp)
    8000452c:	64a2                	ld	s1,8(sp)
    8000452e:	6105                	addi	sp,sp,32
    80004530:	8082                	ret

0000000080004532 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004532:	1101                	addi	sp,sp,-32
    80004534:	ec06                	sd	ra,24(sp)
    80004536:	e822                	sd	s0,16(sp)
    80004538:	e426                	sd	s1,8(sp)
    8000453a:	1000                	addi	s0,sp,32
    8000453c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000453e:	0001d517          	auipc	a0,0x1d
    80004542:	07a50513          	addi	a0,a0,122 # 800215b8 <ftable>
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	69e080e7          	jalr	1694(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000454e:	40dc                	lw	a5,4(s1)
    80004550:	02f05263          	blez	a5,80004574 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004554:	2785                	addiw	a5,a5,1
    80004556:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004558:	0001d517          	auipc	a0,0x1d
    8000455c:	06050513          	addi	a0,a0,96 # 800215b8 <ftable>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	738080e7          	jalr	1848(ra) # 80000c98 <release>
  return f;
}
    80004568:	8526                	mv	a0,s1
    8000456a:	60e2                	ld	ra,24(sp)
    8000456c:	6442                	ld	s0,16(sp)
    8000456e:	64a2                	ld	s1,8(sp)
    80004570:	6105                	addi	sp,sp,32
    80004572:	8082                	ret
    panic("filedup");
    80004574:	00004517          	auipc	a0,0x4
    80004578:	1b450513          	addi	a0,a0,436 # 80008728 <syscalls+0x260>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	fc2080e7          	jalr	-62(ra) # 8000053e <panic>

0000000080004584 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004584:	7139                	addi	sp,sp,-64
    80004586:	fc06                	sd	ra,56(sp)
    80004588:	f822                	sd	s0,48(sp)
    8000458a:	f426                	sd	s1,40(sp)
    8000458c:	f04a                	sd	s2,32(sp)
    8000458e:	ec4e                	sd	s3,24(sp)
    80004590:	e852                	sd	s4,16(sp)
    80004592:	e456                	sd	s5,8(sp)
    80004594:	0080                	addi	s0,sp,64
    80004596:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004598:	0001d517          	auipc	a0,0x1d
    8000459c:	02050513          	addi	a0,a0,32 # 800215b8 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	644080e7          	jalr	1604(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045a8:	40dc                	lw	a5,4(s1)
    800045aa:	06f05163          	blez	a5,8000460c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045ae:	37fd                	addiw	a5,a5,-1
    800045b0:	0007871b          	sext.w	a4,a5
    800045b4:	c0dc                	sw	a5,4(s1)
    800045b6:	06e04363          	bgtz	a4,8000461c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045ba:	0004a903          	lw	s2,0(s1)
    800045be:	0094ca83          	lbu	s5,9(s1)
    800045c2:	0104ba03          	ld	s4,16(s1)
    800045c6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045ca:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045ce:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045d2:	0001d517          	auipc	a0,0x1d
    800045d6:	fe650513          	addi	a0,a0,-26 # 800215b8 <ftable>
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	6be080e7          	jalr	1726(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800045e2:	4785                	li	a5,1
    800045e4:	04f90d63          	beq	s2,a5,8000463e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045e8:	3979                	addiw	s2,s2,-2
    800045ea:	4785                	li	a5,1
    800045ec:	0527e063          	bltu	a5,s2,8000462c <fileclose+0xa8>
    begin_op();
    800045f0:	00000097          	auipc	ra,0x0
    800045f4:	ac8080e7          	jalr	-1336(ra) # 800040b8 <begin_op>
    iput(ff.ip);
    800045f8:	854e                	mv	a0,s3
    800045fa:	fffff097          	auipc	ra,0xfffff
    800045fe:	2a6080e7          	jalr	678(ra) # 800038a0 <iput>
    end_op();
    80004602:	00000097          	auipc	ra,0x0
    80004606:	b36080e7          	jalr	-1226(ra) # 80004138 <end_op>
    8000460a:	a00d                	j	8000462c <fileclose+0xa8>
    panic("fileclose");
    8000460c:	00004517          	auipc	a0,0x4
    80004610:	12450513          	addi	a0,a0,292 # 80008730 <syscalls+0x268>
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	f2a080e7          	jalr	-214(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000461c:	0001d517          	auipc	a0,0x1d
    80004620:	f9c50513          	addi	a0,a0,-100 # 800215b8 <ftable>
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	674080e7          	jalr	1652(ra) # 80000c98 <release>
  }
}
    8000462c:	70e2                	ld	ra,56(sp)
    8000462e:	7442                	ld	s0,48(sp)
    80004630:	74a2                	ld	s1,40(sp)
    80004632:	7902                	ld	s2,32(sp)
    80004634:	69e2                	ld	s3,24(sp)
    80004636:	6a42                	ld	s4,16(sp)
    80004638:	6aa2                	ld	s5,8(sp)
    8000463a:	6121                	addi	sp,sp,64
    8000463c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000463e:	85d6                	mv	a1,s5
    80004640:	8552                	mv	a0,s4
    80004642:	00000097          	auipc	ra,0x0
    80004646:	34c080e7          	jalr	844(ra) # 8000498e <pipeclose>
    8000464a:	b7cd                	j	8000462c <fileclose+0xa8>

000000008000464c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000464c:	715d                	addi	sp,sp,-80
    8000464e:	e486                	sd	ra,72(sp)
    80004650:	e0a2                	sd	s0,64(sp)
    80004652:	fc26                	sd	s1,56(sp)
    80004654:	f84a                	sd	s2,48(sp)
    80004656:	f44e                	sd	s3,40(sp)
    80004658:	0880                	addi	s0,sp,80
    8000465a:	84aa                	mv	s1,a0
    8000465c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000465e:	ffffd097          	auipc	ra,0xffffd
    80004662:	3c8080e7          	jalr	968(ra) # 80001a26 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004666:	409c                	lw	a5,0(s1)
    80004668:	37f9                	addiw	a5,a5,-2
    8000466a:	4705                	li	a4,1
    8000466c:	04f76763          	bltu	a4,a5,800046ba <filestat+0x6e>
    80004670:	892a                	mv	s2,a0
    ilock(f->ip);
    80004672:	6c88                	ld	a0,24(s1)
    80004674:	fffff097          	auipc	ra,0xfffff
    80004678:	072080e7          	jalr	114(ra) # 800036e6 <ilock>
    stati(f->ip, &st);
    8000467c:	fb840593          	addi	a1,s0,-72
    80004680:	6c88                	ld	a0,24(s1)
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	2ee080e7          	jalr	750(ra) # 80003970 <stati>
    iunlock(f->ip);
    8000468a:	6c88                	ld	a0,24(s1)
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	11c080e7          	jalr	284(ra) # 800037a8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004694:	46e1                	li	a3,24
    80004696:	fb840613          	addi	a2,s0,-72
    8000469a:	85ce                	mv	a1,s3
    8000469c:	05093503          	ld	a0,80(s2)
    800046a0:	ffffd097          	auipc	ra,0xffffd
    800046a4:	fd2080e7          	jalr	-46(ra) # 80001672 <copyout>
    800046a8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046ac:	60a6                	ld	ra,72(sp)
    800046ae:	6406                	ld	s0,64(sp)
    800046b0:	74e2                	ld	s1,56(sp)
    800046b2:	7942                	ld	s2,48(sp)
    800046b4:	79a2                	ld	s3,40(sp)
    800046b6:	6161                	addi	sp,sp,80
    800046b8:	8082                	ret
  return -1;
    800046ba:	557d                	li	a0,-1
    800046bc:	bfc5                	j	800046ac <filestat+0x60>

00000000800046be <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046be:	7179                	addi	sp,sp,-48
    800046c0:	f406                	sd	ra,40(sp)
    800046c2:	f022                	sd	s0,32(sp)
    800046c4:	ec26                	sd	s1,24(sp)
    800046c6:	e84a                	sd	s2,16(sp)
    800046c8:	e44e                	sd	s3,8(sp)
    800046ca:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046cc:	00854783          	lbu	a5,8(a0)
    800046d0:	c3d5                	beqz	a5,80004774 <fileread+0xb6>
    800046d2:	84aa                	mv	s1,a0
    800046d4:	89ae                	mv	s3,a1
    800046d6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046d8:	411c                	lw	a5,0(a0)
    800046da:	4705                	li	a4,1
    800046dc:	04e78963          	beq	a5,a4,8000472e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046e0:	470d                	li	a4,3
    800046e2:	04e78d63          	beq	a5,a4,8000473c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046e6:	4709                	li	a4,2
    800046e8:	06e79e63          	bne	a5,a4,80004764 <fileread+0xa6>
    ilock(f->ip);
    800046ec:	6d08                	ld	a0,24(a0)
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	ff8080e7          	jalr	-8(ra) # 800036e6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046f6:	874a                	mv	a4,s2
    800046f8:	5094                	lw	a3,32(s1)
    800046fa:	864e                	mv	a2,s3
    800046fc:	4585                	li	a1,1
    800046fe:	6c88                	ld	a0,24(s1)
    80004700:	fffff097          	auipc	ra,0xfffff
    80004704:	29a080e7          	jalr	666(ra) # 8000399a <readi>
    80004708:	892a                	mv	s2,a0
    8000470a:	00a05563          	blez	a0,80004714 <fileread+0x56>
      f->off += r;
    8000470e:	509c                	lw	a5,32(s1)
    80004710:	9fa9                	addw	a5,a5,a0
    80004712:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004714:	6c88                	ld	a0,24(s1)
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	092080e7          	jalr	146(ra) # 800037a8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000471e:	854a                	mv	a0,s2
    80004720:	70a2                	ld	ra,40(sp)
    80004722:	7402                	ld	s0,32(sp)
    80004724:	64e2                	ld	s1,24(sp)
    80004726:	6942                	ld	s2,16(sp)
    80004728:	69a2                	ld	s3,8(sp)
    8000472a:	6145                	addi	sp,sp,48
    8000472c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000472e:	6908                	ld	a0,16(a0)
    80004730:	00000097          	auipc	ra,0x0
    80004734:	3c8080e7          	jalr	968(ra) # 80004af8 <piperead>
    80004738:	892a                	mv	s2,a0
    8000473a:	b7d5                	j	8000471e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000473c:	02451783          	lh	a5,36(a0)
    80004740:	03079693          	slli	a3,a5,0x30
    80004744:	92c1                	srli	a3,a3,0x30
    80004746:	4725                	li	a4,9
    80004748:	02d76863          	bltu	a4,a3,80004778 <fileread+0xba>
    8000474c:	0792                	slli	a5,a5,0x4
    8000474e:	0001d717          	auipc	a4,0x1d
    80004752:	dca70713          	addi	a4,a4,-566 # 80021518 <devsw>
    80004756:	97ba                	add	a5,a5,a4
    80004758:	639c                	ld	a5,0(a5)
    8000475a:	c38d                	beqz	a5,8000477c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000475c:	4505                	li	a0,1
    8000475e:	9782                	jalr	a5
    80004760:	892a                	mv	s2,a0
    80004762:	bf75                	j	8000471e <fileread+0x60>
    panic("fileread");
    80004764:	00004517          	auipc	a0,0x4
    80004768:	fdc50513          	addi	a0,a0,-36 # 80008740 <syscalls+0x278>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	dd2080e7          	jalr	-558(ra) # 8000053e <panic>
    return -1;
    80004774:	597d                	li	s2,-1
    80004776:	b765                	j	8000471e <fileread+0x60>
      return -1;
    80004778:	597d                	li	s2,-1
    8000477a:	b755                	j	8000471e <fileread+0x60>
    8000477c:	597d                	li	s2,-1
    8000477e:	b745                	j	8000471e <fileread+0x60>

0000000080004780 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004780:	715d                	addi	sp,sp,-80
    80004782:	e486                	sd	ra,72(sp)
    80004784:	e0a2                	sd	s0,64(sp)
    80004786:	fc26                	sd	s1,56(sp)
    80004788:	f84a                	sd	s2,48(sp)
    8000478a:	f44e                	sd	s3,40(sp)
    8000478c:	f052                	sd	s4,32(sp)
    8000478e:	ec56                	sd	s5,24(sp)
    80004790:	e85a                	sd	s6,16(sp)
    80004792:	e45e                	sd	s7,8(sp)
    80004794:	e062                	sd	s8,0(sp)
    80004796:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004798:	00954783          	lbu	a5,9(a0)
    8000479c:	10078663          	beqz	a5,800048a8 <filewrite+0x128>
    800047a0:	892a                	mv	s2,a0
    800047a2:	8aae                	mv	s5,a1
    800047a4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047a6:	411c                	lw	a5,0(a0)
    800047a8:	4705                	li	a4,1
    800047aa:	02e78263          	beq	a5,a4,800047ce <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ae:	470d                	li	a4,3
    800047b0:	02e78663          	beq	a5,a4,800047dc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047b4:	4709                	li	a4,2
    800047b6:	0ee79163          	bne	a5,a4,80004898 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047ba:	0ac05d63          	blez	a2,80004874 <filewrite+0xf4>
    int i = 0;
    800047be:	4981                	li	s3,0
    800047c0:	6b05                	lui	s6,0x1
    800047c2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047c6:	6b85                	lui	s7,0x1
    800047c8:	c00b8b9b          	addiw	s7,s7,-1024
    800047cc:	a861                	j	80004864 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047ce:	6908                	ld	a0,16(a0)
    800047d0:	00000097          	auipc	ra,0x0
    800047d4:	22e080e7          	jalr	558(ra) # 800049fe <pipewrite>
    800047d8:	8a2a                	mv	s4,a0
    800047da:	a045                	j	8000487a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047dc:	02451783          	lh	a5,36(a0)
    800047e0:	03079693          	slli	a3,a5,0x30
    800047e4:	92c1                	srli	a3,a3,0x30
    800047e6:	4725                	li	a4,9
    800047e8:	0cd76263          	bltu	a4,a3,800048ac <filewrite+0x12c>
    800047ec:	0792                	slli	a5,a5,0x4
    800047ee:	0001d717          	auipc	a4,0x1d
    800047f2:	d2a70713          	addi	a4,a4,-726 # 80021518 <devsw>
    800047f6:	97ba                	add	a5,a5,a4
    800047f8:	679c                	ld	a5,8(a5)
    800047fa:	cbdd                	beqz	a5,800048b0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047fc:	4505                	li	a0,1
    800047fe:	9782                	jalr	a5
    80004800:	8a2a                	mv	s4,a0
    80004802:	a8a5                	j	8000487a <filewrite+0xfa>
    80004804:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	8b0080e7          	jalr	-1872(ra) # 800040b8 <begin_op>
      ilock(f->ip);
    80004810:	01893503          	ld	a0,24(s2)
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	ed2080e7          	jalr	-302(ra) # 800036e6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000481c:	8762                	mv	a4,s8
    8000481e:	02092683          	lw	a3,32(s2)
    80004822:	01598633          	add	a2,s3,s5
    80004826:	4585                	li	a1,1
    80004828:	01893503          	ld	a0,24(s2)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	266080e7          	jalr	614(ra) # 80003a92 <writei>
    80004834:	84aa                	mv	s1,a0
    80004836:	00a05763          	blez	a0,80004844 <filewrite+0xc4>
        f->off += r;
    8000483a:	02092783          	lw	a5,32(s2)
    8000483e:	9fa9                	addw	a5,a5,a0
    80004840:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004844:	01893503          	ld	a0,24(s2)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	f60080e7          	jalr	-160(ra) # 800037a8 <iunlock>
      end_op();
    80004850:	00000097          	auipc	ra,0x0
    80004854:	8e8080e7          	jalr	-1816(ra) # 80004138 <end_op>

      if(r != n1){
    80004858:	009c1f63          	bne	s8,s1,80004876 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000485c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004860:	0149db63          	bge	s3,s4,80004876 <filewrite+0xf6>
      int n1 = n - i;
    80004864:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004868:	84be                	mv	s1,a5
    8000486a:	2781                	sext.w	a5,a5
    8000486c:	f8fb5ce3          	bge	s6,a5,80004804 <filewrite+0x84>
    80004870:	84de                	mv	s1,s7
    80004872:	bf49                	j	80004804 <filewrite+0x84>
    int i = 0;
    80004874:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004876:	013a1f63          	bne	s4,s3,80004894 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000487a:	8552                	mv	a0,s4
    8000487c:	60a6                	ld	ra,72(sp)
    8000487e:	6406                	ld	s0,64(sp)
    80004880:	74e2                	ld	s1,56(sp)
    80004882:	7942                	ld	s2,48(sp)
    80004884:	79a2                	ld	s3,40(sp)
    80004886:	7a02                	ld	s4,32(sp)
    80004888:	6ae2                	ld	s5,24(sp)
    8000488a:	6b42                	ld	s6,16(sp)
    8000488c:	6ba2                	ld	s7,8(sp)
    8000488e:	6c02                	ld	s8,0(sp)
    80004890:	6161                	addi	sp,sp,80
    80004892:	8082                	ret
    ret = (i == n ? n : -1);
    80004894:	5a7d                	li	s4,-1
    80004896:	b7d5                	j	8000487a <filewrite+0xfa>
    panic("filewrite");
    80004898:	00004517          	auipc	a0,0x4
    8000489c:	eb850513          	addi	a0,a0,-328 # 80008750 <syscalls+0x288>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	c9e080e7          	jalr	-866(ra) # 8000053e <panic>
    return -1;
    800048a8:	5a7d                	li	s4,-1
    800048aa:	bfc1                	j	8000487a <filewrite+0xfa>
      return -1;
    800048ac:	5a7d                	li	s4,-1
    800048ae:	b7f1                	j	8000487a <filewrite+0xfa>
    800048b0:	5a7d                	li	s4,-1
    800048b2:	b7e1                	j	8000487a <filewrite+0xfa>

00000000800048b4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048b4:	7179                	addi	sp,sp,-48
    800048b6:	f406                	sd	ra,40(sp)
    800048b8:	f022                	sd	s0,32(sp)
    800048ba:	ec26                	sd	s1,24(sp)
    800048bc:	e84a                	sd	s2,16(sp)
    800048be:	e44e                	sd	s3,8(sp)
    800048c0:	e052                	sd	s4,0(sp)
    800048c2:	1800                	addi	s0,sp,48
    800048c4:	84aa                	mv	s1,a0
    800048c6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048c8:	0005b023          	sd	zero,0(a1)
    800048cc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	bf8080e7          	jalr	-1032(ra) # 800044c8 <filealloc>
    800048d8:	e088                	sd	a0,0(s1)
    800048da:	c551                	beqz	a0,80004966 <pipealloc+0xb2>
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	bec080e7          	jalr	-1044(ra) # 800044c8 <filealloc>
    800048e4:	00aa3023          	sd	a0,0(s4)
    800048e8:	c92d                	beqz	a0,8000495a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	20a080e7          	jalr	522(ra) # 80000af4 <kalloc>
    800048f2:	892a                	mv	s2,a0
    800048f4:	c125                	beqz	a0,80004954 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048f6:	4985                	li	s3,1
    800048f8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048fc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004900:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004904:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004908:	00004597          	auipc	a1,0x4
    8000490c:	e5858593          	addi	a1,a1,-424 # 80008760 <syscalls+0x298>
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004918:	609c                	ld	a5,0(s1)
    8000491a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000491e:	609c                	ld	a5,0(s1)
    80004920:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004924:	609c                	ld	a5,0(s1)
    80004926:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000492a:	609c                	ld	a5,0(s1)
    8000492c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004930:	000a3783          	ld	a5,0(s4)
    80004934:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004938:	000a3783          	ld	a5,0(s4)
    8000493c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004940:	000a3783          	ld	a5,0(s4)
    80004944:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004948:	000a3783          	ld	a5,0(s4)
    8000494c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004950:	4501                	li	a0,0
    80004952:	a025                	j	8000497a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004954:	6088                	ld	a0,0(s1)
    80004956:	e501                	bnez	a0,8000495e <pipealloc+0xaa>
    80004958:	a039                	j	80004966 <pipealloc+0xb2>
    8000495a:	6088                	ld	a0,0(s1)
    8000495c:	c51d                	beqz	a0,8000498a <pipealloc+0xd6>
    fileclose(*f0);
    8000495e:	00000097          	auipc	ra,0x0
    80004962:	c26080e7          	jalr	-986(ra) # 80004584 <fileclose>
  if(*f1)
    80004966:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000496a:	557d                	li	a0,-1
  if(*f1)
    8000496c:	c799                	beqz	a5,8000497a <pipealloc+0xc6>
    fileclose(*f1);
    8000496e:	853e                	mv	a0,a5
    80004970:	00000097          	auipc	ra,0x0
    80004974:	c14080e7          	jalr	-1004(ra) # 80004584 <fileclose>
  return -1;
    80004978:	557d                	li	a0,-1
}
    8000497a:	70a2                	ld	ra,40(sp)
    8000497c:	7402                	ld	s0,32(sp)
    8000497e:	64e2                	ld	s1,24(sp)
    80004980:	6942                	ld	s2,16(sp)
    80004982:	69a2                	ld	s3,8(sp)
    80004984:	6a02                	ld	s4,0(sp)
    80004986:	6145                	addi	sp,sp,48
    80004988:	8082                	ret
  return -1;
    8000498a:	557d                	li	a0,-1
    8000498c:	b7fd                	j	8000497a <pipealloc+0xc6>

000000008000498e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000498e:	1101                	addi	sp,sp,-32
    80004990:	ec06                	sd	ra,24(sp)
    80004992:	e822                	sd	s0,16(sp)
    80004994:	e426                	sd	s1,8(sp)
    80004996:	e04a                	sd	s2,0(sp)
    80004998:	1000                	addi	s0,sp,32
    8000499a:	84aa                	mv	s1,a0
    8000499c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	246080e7          	jalr	582(ra) # 80000be4 <acquire>
  if(writable){
    800049a6:	02090d63          	beqz	s2,800049e0 <pipeclose+0x52>
    pi->writeopen = 0;
    800049aa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049ae:	21848513          	addi	a0,s1,536
    800049b2:	ffffe097          	auipc	ra,0xffffe
    800049b6:	8ec080e7          	jalr	-1812(ra) # 8000229e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049ba:	2204b783          	ld	a5,544(s1)
    800049be:	eb95                	bnez	a5,800049f2 <pipeclose+0x64>
    release(&pi->lock);
    800049c0:	8526                	mv	a0,s1
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	2d6080e7          	jalr	726(ra) # 80000c98 <release>
    kfree((char*)pi);
    800049ca:	8526                	mv	a0,s1
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	02c080e7          	jalr	44(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800049d4:	60e2                	ld	ra,24(sp)
    800049d6:	6442                	ld	s0,16(sp)
    800049d8:	64a2                	ld	s1,8(sp)
    800049da:	6902                	ld	s2,0(sp)
    800049dc:	6105                	addi	sp,sp,32
    800049de:	8082                	ret
    pi->readopen = 0;
    800049e0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049e4:	21c48513          	addi	a0,s1,540
    800049e8:	ffffe097          	auipc	ra,0xffffe
    800049ec:	8b6080e7          	jalr	-1866(ra) # 8000229e <wakeup>
    800049f0:	b7e9                	j	800049ba <pipeclose+0x2c>
    release(&pi->lock);
    800049f2:	8526                	mv	a0,s1
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	2a4080e7          	jalr	676(ra) # 80000c98 <release>
}
    800049fc:	bfe1                	j	800049d4 <pipeclose+0x46>

00000000800049fe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049fe:	7159                	addi	sp,sp,-112
    80004a00:	f486                	sd	ra,104(sp)
    80004a02:	f0a2                	sd	s0,96(sp)
    80004a04:	eca6                	sd	s1,88(sp)
    80004a06:	e8ca                	sd	s2,80(sp)
    80004a08:	e4ce                	sd	s3,72(sp)
    80004a0a:	e0d2                	sd	s4,64(sp)
    80004a0c:	fc56                	sd	s5,56(sp)
    80004a0e:	f85a                	sd	s6,48(sp)
    80004a10:	f45e                	sd	s7,40(sp)
    80004a12:	f062                	sd	s8,32(sp)
    80004a14:	ec66                	sd	s9,24(sp)
    80004a16:	1880                	addi	s0,sp,112
    80004a18:	84aa                	mv	s1,a0
    80004a1a:	8aae                	mv	s5,a1
    80004a1c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a1e:	ffffd097          	auipc	ra,0xffffd
    80004a22:	008080e7          	jalr	8(ra) # 80001a26 <myproc>
    80004a26:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a28:	8526                	mv	a0,s1
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	1ba080e7          	jalr	442(ra) # 80000be4 <acquire>
  while(i < n){
    80004a32:	0d405163          	blez	s4,80004af4 <pipewrite+0xf6>
    80004a36:	8ba6                	mv	s7,s1
  int i = 0;
    80004a38:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a3a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a3c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a40:	21c48c13          	addi	s8,s1,540
    80004a44:	a08d                	j	80004aa6 <pipewrite+0xa8>
      release(&pi->lock);
    80004a46:	8526                	mv	a0,s1
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	250080e7          	jalr	592(ra) # 80000c98 <release>
      return -1;
    80004a50:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a52:	854a                	mv	a0,s2
    80004a54:	70a6                	ld	ra,104(sp)
    80004a56:	7406                	ld	s0,96(sp)
    80004a58:	64e6                	ld	s1,88(sp)
    80004a5a:	6946                	ld	s2,80(sp)
    80004a5c:	69a6                	ld	s3,72(sp)
    80004a5e:	6a06                	ld	s4,64(sp)
    80004a60:	7ae2                	ld	s5,56(sp)
    80004a62:	7b42                	ld	s6,48(sp)
    80004a64:	7ba2                	ld	s7,40(sp)
    80004a66:	7c02                	ld	s8,32(sp)
    80004a68:	6ce2                	ld	s9,24(sp)
    80004a6a:	6165                	addi	sp,sp,112
    80004a6c:	8082                	ret
      wakeup(&pi->nread);
    80004a6e:	8566                	mv	a0,s9
    80004a70:	ffffe097          	auipc	ra,0xffffe
    80004a74:	82e080e7          	jalr	-2002(ra) # 8000229e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a78:	85de                	mv	a1,s7
    80004a7a:	8562                	mv	a0,s8
    80004a7c:	ffffd097          	auipc	ra,0xffffd
    80004a80:	696080e7          	jalr	1686(ra) # 80002112 <sleep>
    80004a84:	a839                	j	80004aa2 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a86:	21c4a783          	lw	a5,540(s1)
    80004a8a:	0017871b          	addiw	a4,a5,1
    80004a8e:	20e4ae23          	sw	a4,540(s1)
    80004a92:	1ff7f793          	andi	a5,a5,511
    80004a96:	97a6                	add	a5,a5,s1
    80004a98:	f9f44703          	lbu	a4,-97(s0)
    80004a9c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004aa0:	2905                	addiw	s2,s2,1
  while(i < n){
    80004aa2:	03495d63          	bge	s2,s4,80004adc <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004aa6:	2204a783          	lw	a5,544(s1)
    80004aaa:	dfd1                	beqz	a5,80004a46 <pipewrite+0x48>
    80004aac:	0289a783          	lw	a5,40(s3)
    80004ab0:	fbd9                	bnez	a5,80004a46 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ab2:	2184a783          	lw	a5,536(s1)
    80004ab6:	21c4a703          	lw	a4,540(s1)
    80004aba:	2007879b          	addiw	a5,a5,512
    80004abe:	faf708e3          	beq	a4,a5,80004a6e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ac2:	4685                	li	a3,1
    80004ac4:	01590633          	add	a2,s2,s5
    80004ac8:	f9f40593          	addi	a1,s0,-97
    80004acc:	0509b503          	ld	a0,80(s3)
    80004ad0:	ffffd097          	auipc	ra,0xffffd
    80004ad4:	c2e080e7          	jalr	-978(ra) # 800016fe <copyin>
    80004ad8:	fb6517e3          	bne	a0,s6,80004a86 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004adc:	21848513          	addi	a0,s1,536
    80004ae0:	ffffd097          	auipc	ra,0xffffd
    80004ae4:	7be080e7          	jalr	1982(ra) # 8000229e <wakeup>
  release(&pi->lock);
    80004ae8:	8526                	mv	a0,s1
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	1ae080e7          	jalr	430(ra) # 80000c98 <release>
  return i;
    80004af2:	b785                	j	80004a52 <pipewrite+0x54>
  int i = 0;
    80004af4:	4901                	li	s2,0
    80004af6:	b7dd                	j	80004adc <pipewrite+0xde>

0000000080004af8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004af8:	715d                	addi	sp,sp,-80
    80004afa:	e486                	sd	ra,72(sp)
    80004afc:	e0a2                	sd	s0,64(sp)
    80004afe:	fc26                	sd	s1,56(sp)
    80004b00:	f84a                	sd	s2,48(sp)
    80004b02:	f44e                	sd	s3,40(sp)
    80004b04:	f052                	sd	s4,32(sp)
    80004b06:	ec56                	sd	s5,24(sp)
    80004b08:	e85a                	sd	s6,16(sp)
    80004b0a:	0880                	addi	s0,sp,80
    80004b0c:	84aa                	mv	s1,a0
    80004b0e:	892e                	mv	s2,a1
    80004b10:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b12:	ffffd097          	auipc	ra,0xffffd
    80004b16:	f14080e7          	jalr	-236(ra) # 80001a26 <myproc>
    80004b1a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b1c:	8b26                	mv	s6,s1
    80004b1e:	8526                	mv	a0,s1
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	0c4080e7          	jalr	196(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b28:	2184a703          	lw	a4,536(s1)
    80004b2c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b30:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b34:	02f71463          	bne	a4,a5,80004b5c <piperead+0x64>
    80004b38:	2244a783          	lw	a5,548(s1)
    80004b3c:	c385                	beqz	a5,80004b5c <piperead+0x64>
    if(pr->killed){
    80004b3e:	028a2783          	lw	a5,40(s4)
    80004b42:	ebc1                	bnez	a5,80004bd2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b44:	85da                	mv	a1,s6
    80004b46:	854e                	mv	a0,s3
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	5ca080e7          	jalr	1482(ra) # 80002112 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b50:	2184a703          	lw	a4,536(s1)
    80004b54:	21c4a783          	lw	a5,540(s1)
    80004b58:	fef700e3          	beq	a4,a5,80004b38 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b5c:	09505263          	blez	s5,80004be0 <piperead+0xe8>
    80004b60:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b62:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b64:	2184a783          	lw	a5,536(s1)
    80004b68:	21c4a703          	lw	a4,540(s1)
    80004b6c:	02f70d63          	beq	a4,a5,80004ba6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b70:	0017871b          	addiw	a4,a5,1
    80004b74:	20e4ac23          	sw	a4,536(s1)
    80004b78:	1ff7f793          	andi	a5,a5,511
    80004b7c:	97a6                	add	a5,a5,s1
    80004b7e:	0187c783          	lbu	a5,24(a5)
    80004b82:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b86:	4685                	li	a3,1
    80004b88:	fbf40613          	addi	a2,s0,-65
    80004b8c:	85ca                	mv	a1,s2
    80004b8e:	050a3503          	ld	a0,80(s4)
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	ae0080e7          	jalr	-1312(ra) # 80001672 <copyout>
    80004b9a:	01650663          	beq	a0,s6,80004ba6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b9e:	2985                	addiw	s3,s3,1
    80004ba0:	0905                	addi	s2,s2,1
    80004ba2:	fd3a91e3          	bne	s5,s3,80004b64 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ba6:	21c48513          	addi	a0,s1,540
    80004baa:	ffffd097          	auipc	ra,0xffffd
    80004bae:	6f4080e7          	jalr	1780(ra) # 8000229e <wakeup>
  release(&pi->lock);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	0e4080e7          	jalr	228(ra) # 80000c98 <release>
  return i;
}
    80004bbc:	854e                	mv	a0,s3
    80004bbe:	60a6                	ld	ra,72(sp)
    80004bc0:	6406                	ld	s0,64(sp)
    80004bc2:	74e2                	ld	s1,56(sp)
    80004bc4:	7942                	ld	s2,48(sp)
    80004bc6:	79a2                	ld	s3,40(sp)
    80004bc8:	7a02                	ld	s4,32(sp)
    80004bca:	6ae2                	ld	s5,24(sp)
    80004bcc:	6b42                	ld	s6,16(sp)
    80004bce:	6161                	addi	sp,sp,80
    80004bd0:	8082                	ret
      release(&pi->lock);
    80004bd2:	8526                	mv	a0,s1
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	0c4080e7          	jalr	196(ra) # 80000c98 <release>
      return -1;
    80004bdc:	59fd                	li	s3,-1
    80004bde:	bff9                	j	80004bbc <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004be0:	4981                	li	s3,0
    80004be2:	b7d1                	j	80004ba6 <piperead+0xae>

0000000080004be4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004be4:	df010113          	addi	sp,sp,-528
    80004be8:	20113423          	sd	ra,520(sp)
    80004bec:	20813023          	sd	s0,512(sp)
    80004bf0:	ffa6                	sd	s1,504(sp)
    80004bf2:	fbca                	sd	s2,496(sp)
    80004bf4:	f7ce                	sd	s3,488(sp)
    80004bf6:	f3d2                	sd	s4,480(sp)
    80004bf8:	efd6                	sd	s5,472(sp)
    80004bfa:	ebda                	sd	s6,464(sp)
    80004bfc:	e7de                	sd	s7,456(sp)
    80004bfe:	e3e2                	sd	s8,448(sp)
    80004c00:	ff66                	sd	s9,440(sp)
    80004c02:	fb6a                	sd	s10,432(sp)
    80004c04:	f76e                	sd	s11,424(sp)
    80004c06:	0c00                	addi	s0,sp,528
    80004c08:	84aa                	mv	s1,a0
    80004c0a:	dea43c23          	sd	a0,-520(s0)
    80004c0e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c12:	ffffd097          	auipc	ra,0xffffd
    80004c16:	e14080e7          	jalr	-492(ra) # 80001a26 <myproc>
    80004c1a:	892a                	mv	s2,a0

  begin_op();
    80004c1c:	fffff097          	auipc	ra,0xfffff
    80004c20:	49c080e7          	jalr	1180(ra) # 800040b8 <begin_op>

  if((ip = namei(path)) == 0){
    80004c24:	8526                	mv	a0,s1
    80004c26:	fffff097          	auipc	ra,0xfffff
    80004c2a:	276080e7          	jalr	630(ra) # 80003e9c <namei>
    80004c2e:	c92d                	beqz	a0,80004ca0 <exec+0xbc>
    80004c30:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c32:	fffff097          	auipc	ra,0xfffff
    80004c36:	ab4080e7          	jalr	-1356(ra) # 800036e6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c3a:	04000713          	li	a4,64
    80004c3e:	4681                	li	a3,0
    80004c40:	e5040613          	addi	a2,s0,-432
    80004c44:	4581                	li	a1,0
    80004c46:	8526                	mv	a0,s1
    80004c48:	fffff097          	auipc	ra,0xfffff
    80004c4c:	d52080e7          	jalr	-686(ra) # 8000399a <readi>
    80004c50:	04000793          	li	a5,64
    80004c54:	00f51a63          	bne	a0,a5,80004c68 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c58:	e5042703          	lw	a4,-432(s0)
    80004c5c:	464c47b7          	lui	a5,0x464c4
    80004c60:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c64:	04f70463          	beq	a4,a5,80004cac <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c68:	8526                	mv	a0,s1
    80004c6a:	fffff097          	auipc	ra,0xfffff
    80004c6e:	cde080e7          	jalr	-802(ra) # 80003948 <iunlockput>
    end_op();
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	4c6080e7          	jalr	1222(ra) # 80004138 <end_op>
  }
  return -1;
    80004c7a:	557d                	li	a0,-1
}
    80004c7c:	20813083          	ld	ra,520(sp)
    80004c80:	20013403          	ld	s0,512(sp)
    80004c84:	74fe                	ld	s1,504(sp)
    80004c86:	795e                	ld	s2,496(sp)
    80004c88:	79be                	ld	s3,488(sp)
    80004c8a:	7a1e                	ld	s4,480(sp)
    80004c8c:	6afe                	ld	s5,472(sp)
    80004c8e:	6b5e                	ld	s6,464(sp)
    80004c90:	6bbe                	ld	s7,456(sp)
    80004c92:	6c1e                	ld	s8,448(sp)
    80004c94:	7cfa                	ld	s9,440(sp)
    80004c96:	7d5a                	ld	s10,432(sp)
    80004c98:	7dba                	ld	s11,424(sp)
    80004c9a:	21010113          	addi	sp,sp,528
    80004c9e:	8082                	ret
    end_op();
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	498080e7          	jalr	1176(ra) # 80004138 <end_op>
    return -1;
    80004ca8:	557d                	li	a0,-1
    80004caa:	bfc9                	j	80004c7c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cac:	854a                	mv	a0,s2
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	e68080e7          	jalr	-408(ra) # 80001b16 <proc_pagetable>
    80004cb6:	8baa                	mv	s7,a0
    80004cb8:	d945                	beqz	a0,80004c68 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cba:	e7042983          	lw	s3,-400(s0)
    80004cbe:	e8845783          	lhu	a5,-376(s0)
    80004cc2:	c7ad                	beqz	a5,80004d2c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cc4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cc6:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004cc8:	6c85                	lui	s9,0x1
    80004cca:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cce:	def43823          	sd	a5,-528(s0)
    80004cd2:	a42d                	j	80004efc <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cd4:	00004517          	auipc	a0,0x4
    80004cd8:	a9450513          	addi	a0,a0,-1388 # 80008768 <syscalls+0x2a0>
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	862080e7          	jalr	-1950(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ce4:	8756                	mv	a4,s5
    80004ce6:	012d86bb          	addw	a3,s11,s2
    80004cea:	4581                	li	a1,0
    80004cec:	8526                	mv	a0,s1
    80004cee:	fffff097          	auipc	ra,0xfffff
    80004cf2:	cac080e7          	jalr	-852(ra) # 8000399a <readi>
    80004cf6:	2501                	sext.w	a0,a0
    80004cf8:	1aaa9963          	bne	s5,a0,80004eaa <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004cfc:	6785                	lui	a5,0x1
    80004cfe:	0127893b          	addw	s2,a5,s2
    80004d02:	77fd                	lui	a5,0xfffff
    80004d04:	01478a3b          	addw	s4,a5,s4
    80004d08:	1f897163          	bgeu	s2,s8,80004eea <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d0c:	02091593          	slli	a1,s2,0x20
    80004d10:	9181                	srli	a1,a1,0x20
    80004d12:	95ea                	add	a1,a1,s10
    80004d14:	855e                	mv	a0,s7
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	358080e7          	jalr	856(ra) # 8000106e <walkaddr>
    80004d1e:	862a                	mv	a2,a0
    if(pa == 0)
    80004d20:	d955                	beqz	a0,80004cd4 <exec+0xf0>
      n = PGSIZE;
    80004d22:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d24:	fd9a70e3          	bgeu	s4,s9,80004ce4 <exec+0x100>
      n = sz - i;
    80004d28:	8ad2                	mv	s5,s4
    80004d2a:	bf6d                	j	80004ce4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d2c:	4901                	li	s2,0
  iunlockput(ip);
    80004d2e:	8526                	mv	a0,s1
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	c18080e7          	jalr	-1000(ra) # 80003948 <iunlockput>
  end_op();
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	400080e7          	jalr	1024(ra) # 80004138 <end_op>
  p = myproc();
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	ce6080e7          	jalr	-794(ra) # 80001a26 <myproc>
    80004d48:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d4a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d4e:	6785                	lui	a5,0x1
    80004d50:	17fd                	addi	a5,a5,-1
    80004d52:	993e                	add	s2,s2,a5
    80004d54:	757d                	lui	a0,0xfffff
    80004d56:	00a977b3          	and	a5,s2,a0
    80004d5a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d5e:	6609                	lui	a2,0x2
    80004d60:	963e                	add	a2,a2,a5
    80004d62:	85be                	mv	a1,a5
    80004d64:	855e                	mv	a0,s7
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	6bc080e7          	jalr	1724(ra) # 80001422 <uvmalloc>
    80004d6e:	8b2a                	mv	s6,a0
  ip = 0;
    80004d70:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d72:	12050c63          	beqz	a0,80004eaa <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d76:	75f9                	lui	a1,0xffffe
    80004d78:	95aa                	add	a1,a1,a0
    80004d7a:	855e                	mv	a0,s7
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	8c4080e7          	jalr	-1852(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d84:	7c7d                	lui	s8,0xfffff
    80004d86:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d88:	e0043783          	ld	a5,-512(s0)
    80004d8c:	6388                	ld	a0,0(a5)
    80004d8e:	c535                	beqz	a0,80004dfa <exec+0x216>
    80004d90:	e9040993          	addi	s3,s0,-368
    80004d94:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d98:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	0ca080e7          	jalr	202(ra) # 80000e64 <strlen>
    80004da2:	2505                	addiw	a0,a0,1
    80004da4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004da8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004dac:	13896363          	bltu	s2,s8,80004ed2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004db0:	e0043d83          	ld	s11,-512(s0)
    80004db4:	000dba03          	ld	s4,0(s11)
    80004db8:	8552                	mv	a0,s4
    80004dba:	ffffc097          	auipc	ra,0xffffc
    80004dbe:	0aa080e7          	jalr	170(ra) # 80000e64 <strlen>
    80004dc2:	0015069b          	addiw	a3,a0,1
    80004dc6:	8652                	mv	a2,s4
    80004dc8:	85ca                	mv	a1,s2
    80004dca:	855e                	mv	a0,s7
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	8a6080e7          	jalr	-1882(ra) # 80001672 <copyout>
    80004dd4:	10054363          	bltz	a0,80004eda <exec+0x2f6>
    ustack[argc] = sp;
    80004dd8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ddc:	0485                	addi	s1,s1,1
    80004dde:	008d8793          	addi	a5,s11,8
    80004de2:	e0f43023          	sd	a5,-512(s0)
    80004de6:	008db503          	ld	a0,8(s11)
    80004dea:	c911                	beqz	a0,80004dfe <exec+0x21a>
    if(argc >= MAXARG)
    80004dec:	09a1                	addi	s3,s3,8
    80004dee:	fb3c96e3          	bne	s9,s3,80004d9a <exec+0x1b6>
  sz = sz1;
    80004df2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004df6:	4481                	li	s1,0
    80004df8:	a84d                	j	80004eaa <exec+0x2c6>
  sp = sz;
    80004dfa:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dfc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dfe:	00349793          	slli	a5,s1,0x3
    80004e02:	f9040713          	addi	a4,s0,-112
    80004e06:	97ba                	add	a5,a5,a4
    80004e08:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e0c:	00148693          	addi	a3,s1,1
    80004e10:	068e                	slli	a3,a3,0x3
    80004e12:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e16:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e1a:	01897663          	bgeu	s2,s8,80004e26 <exec+0x242>
  sz = sz1;
    80004e1e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e22:	4481                	li	s1,0
    80004e24:	a059                	j	80004eaa <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e26:	e9040613          	addi	a2,s0,-368
    80004e2a:	85ca                	mv	a1,s2
    80004e2c:	855e                	mv	a0,s7
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	844080e7          	jalr	-1980(ra) # 80001672 <copyout>
    80004e36:	0a054663          	bltz	a0,80004ee2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e3a:	058ab783          	ld	a5,88(s5)
    80004e3e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e42:	df843783          	ld	a5,-520(s0)
    80004e46:	0007c703          	lbu	a4,0(a5)
    80004e4a:	cf11                	beqz	a4,80004e66 <exec+0x282>
    80004e4c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e4e:	02f00693          	li	a3,47
    80004e52:	a039                	j	80004e60 <exec+0x27c>
      last = s+1;
    80004e54:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e58:	0785                	addi	a5,a5,1
    80004e5a:	fff7c703          	lbu	a4,-1(a5)
    80004e5e:	c701                	beqz	a4,80004e66 <exec+0x282>
    if(*s == '/')
    80004e60:	fed71ce3          	bne	a4,a3,80004e58 <exec+0x274>
    80004e64:	bfc5                	j	80004e54 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e66:	4641                	li	a2,16
    80004e68:	df843583          	ld	a1,-520(s0)
    80004e6c:	158a8513          	addi	a0,s5,344
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	fc2080e7          	jalr	-62(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e78:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e7c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e80:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e84:	058ab783          	ld	a5,88(s5)
    80004e88:	e6843703          	ld	a4,-408(s0)
    80004e8c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e8e:	058ab783          	ld	a5,88(s5)
    80004e92:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e96:	85ea                	mv	a1,s10
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	d1a080e7          	jalr	-742(ra) # 80001bb2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ea0:	0004851b          	sext.w	a0,s1
    80004ea4:	bbe1                	j	80004c7c <exec+0x98>
    80004ea6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004eaa:	e0843583          	ld	a1,-504(s0)
    80004eae:	855e                	mv	a0,s7
    80004eb0:	ffffd097          	auipc	ra,0xffffd
    80004eb4:	d02080e7          	jalr	-766(ra) # 80001bb2 <proc_freepagetable>
  if(ip){
    80004eb8:	da0498e3          	bnez	s1,80004c68 <exec+0x84>
  return -1;
    80004ebc:	557d                	li	a0,-1
    80004ebe:	bb7d                	j	80004c7c <exec+0x98>
    80004ec0:	e1243423          	sd	s2,-504(s0)
    80004ec4:	b7dd                	j	80004eaa <exec+0x2c6>
    80004ec6:	e1243423          	sd	s2,-504(s0)
    80004eca:	b7c5                	j	80004eaa <exec+0x2c6>
    80004ecc:	e1243423          	sd	s2,-504(s0)
    80004ed0:	bfe9                	j	80004eaa <exec+0x2c6>
  sz = sz1;
    80004ed2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ed6:	4481                	li	s1,0
    80004ed8:	bfc9                	j	80004eaa <exec+0x2c6>
  sz = sz1;
    80004eda:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ede:	4481                	li	s1,0
    80004ee0:	b7e9                	j	80004eaa <exec+0x2c6>
  sz = sz1;
    80004ee2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ee6:	4481                	li	s1,0
    80004ee8:	b7c9                	j	80004eaa <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004eea:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eee:	2b05                	addiw	s6,s6,1
    80004ef0:	0389899b          	addiw	s3,s3,56
    80004ef4:	e8845783          	lhu	a5,-376(s0)
    80004ef8:	e2fb5be3          	bge	s6,a5,80004d2e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004efc:	2981                	sext.w	s3,s3
    80004efe:	03800713          	li	a4,56
    80004f02:	86ce                	mv	a3,s3
    80004f04:	e1840613          	addi	a2,s0,-488
    80004f08:	4581                	li	a1,0
    80004f0a:	8526                	mv	a0,s1
    80004f0c:	fffff097          	auipc	ra,0xfffff
    80004f10:	a8e080e7          	jalr	-1394(ra) # 8000399a <readi>
    80004f14:	03800793          	li	a5,56
    80004f18:	f8f517e3          	bne	a0,a5,80004ea6 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f1c:	e1842783          	lw	a5,-488(s0)
    80004f20:	4705                	li	a4,1
    80004f22:	fce796e3          	bne	a5,a4,80004eee <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f26:	e4043603          	ld	a2,-448(s0)
    80004f2a:	e3843783          	ld	a5,-456(s0)
    80004f2e:	f8f669e3          	bltu	a2,a5,80004ec0 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f32:	e2843783          	ld	a5,-472(s0)
    80004f36:	963e                	add	a2,a2,a5
    80004f38:	f8f667e3          	bltu	a2,a5,80004ec6 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f3c:	85ca                	mv	a1,s2
    80004f3e:	855e                	mv	a0,s7
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	4e2080e7          	jalr	1250(ra) # 80001422 <uvmalloc>
    80004f48:	e0a43423          	sd	a0,-504(s0)
    80004f4c:	d141                	beqz	a0,80004ecc <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004f4e:	e2843d03          	ld	s10,-472(s0)
    80004f52:	df043783          	ld	a5,-528(s0)
    80004f56:	00fd77b3          	and	a5,s10,a5
    80004f5a:	fba1                	bnez	a5,80004eaa <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f5c:	e2042d83          	lw	s11,-480(s0)
    80004f60:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f64:	f80c03e3          	beqz	s8,80004eea <exec+0x306>
    80004f68:	8a62                	mv	s4,s8
    80004f6a:	4901                	li	s2,0
    80004f6c:	b345                	j	80004d0c <exec+0x128>

0000000080004f6e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f6e:	7179                	addi	sp,sp,-48
    80004f70:	f406                	sd	ra,40(sp)
    80004f72:	f022                	sd	s0,32(sp)
    80004f74:	ec26                	sd	s1,24(sp)
    80004f76:	e84a                	sd	s2,16(sp)
    80004f78:	1800                	addi	s0,sp,48
    80004f7a:	892e                	mv	s2,a1
    80004f7c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f7e:	fdc40593          	addi	a1,s0,-36
    80004f82:	ffffe097          	auipc	ra,0xffffe
    80004f86:	b80080e7          	jalr	-1152(ra) # 80002b02 <argint>
    80004f8a:	04054063          	bltz	a0,80004fca <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f8e:	fdc42703          	lw	a4,-36(s0)
    80004f92:	47bd                	li	a5,15
    80004f94:	02e7ed63          	bltu	a5,a4,80004fce <argfd+0x60>
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	a8e080e7          	jalr	-1394(ra) # 80001a26 <myproc>
    80004fa0:	fdc42703          	lw	a4,-36(s0)
    80004fa4:	01a70793          	addi	a5,a4,26
    80004fa8:	078e                	slli	a5,a5,0x3
    80004faa:	953e                	add	a0,a0,a5
    80004fac:	611c                	ld	a5,0(a0)
    80004fae:	c395                	beqz	a5,80004fd2 <argfd+0x64>
    return -1;
  if(pfd)
    80004fb0:	00090463          	beqz	s2,80004fb8 <argfd+0x4a>
    *pfd = fd;
    80004fb4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fb8:	4501                	li	a0,0
  if(pf)
    80004fba:	c091                	beqz	s1,80004fbe <argfd+0x50>
    *pf = f;
    80004fbc:	e09c                	sd	a5,0(s1)
}
    80004fbe:	70a2                	ld	ra,40(sp)
    80004fc0:	7402                	ld	s0,32(sp)
    80004fc2:	64e2                	ld	s1,24(sp)
    80004fc4:	6942                	ld	s2,16(sp)
    80004fc6:	6145                	addi	sp,sp,48
    80004fc8:	8082                	ret
    return -1;
    80004fca:	557d                	li	a0,-1
    80004fcc:	bfcd                	j	80004fbe <argfd+0x50>
    return -1;
    80004fce:	557d                	li	a0,-1
    80004fd0:	b7fd                	j	80004fbe <argfd+0x50>
    80004fd2:	557d                	li	a0,-1
    80004fd4:	b7ed                	j	80004fbe <argfd+0x50>

0000000080004fd6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fd6:	1101                	addi	sp,sp,-32
    80004fd8:	ec06                	sd	ra,24(sp)
    80004fda:	e822                	sd	s0,16(sp)
    80004fdc:	e426                	sd	s1,8(sp)
    80004fde:	1000                	addi	s0,sp,32
    80004fe0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fe2:	ffffd097          	auipc	ra,0xffffd
    80004fe6:	a44080e7          	jalr	-1468(ra) # 80001a26 <myproc>
    80004fea:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fec:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004ff0:	4501                	li	a0,0
    80004ff2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ff4:	6398                	ld	a4,0(a5)
    80004ff6:	cb19                	beqz	a4,8000500c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004ff8:	2505                	addiw	a0,a0,1
    80004ffa:	07a1                	addi	a5,a5,8
    80004ffc:	fed51ce3          	bne	a0,a3,80004ff4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005000:	557d                	li	a0,-1
}
    80005002:	60e2                	ld	ra,24(sp)
    80005004:	6442                	ld	s0,16(sp)
    80005006:	64a2                	ld	s1,8(sp)
    80005008:	6105                	addi	sp,sp,32
    8000500a:	8082                	ret
      p->ofile[fd] = f;
    8000500c:	01a50793          	addi	a5,a0,26
    80005010:	078e                	slli	a5,a5,0x3
    80005012:	963e                	add	a2,a2,a5
    80005014:	e204                	sd	s1,0(a2)
      return fd;
    80005016:	b7f5                	j	80005002 <fdalloc+0x2c>

0000000080005018 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005018:	715d                	addi	sp,sp,-80
    8000501a:	e486                	sd	ra,72(sp)
    8000501c:	e0a2                	sd	s0,64(sp)
    8000501e:	fc26                	sd	s1,56(sp)
    80005020:	f84a                	sd	s2,48(sp)
    80005022:	f44e                	sd	s3,40(sp)
    80005024:	f052                	sd	s4,32(sp)
    80005026:	ec56                	sd	s5,24(sp)
    80005028:	0880                	addi	s0,sp,80
    8000502a:	89ae                	mv	s3,a1
    8000502c:	8ab2                	mv	s5,a2
    8000502e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005030:	fb040593          	addi	a1,s0,-80
    80005034:	fffff097          	auipc	ra,0xfffff
    80005038:	e86080e7          	jalr	-378(ra) # 80003eba <nameiparent>
    8000503c:	892a                	mv	s2,a0
    8000503e:	12050f63          	beqz	a0,8000517c <create+0x164>
    return 0;

  ilock(dp);
    80005042:	ffffe097          	auipc	ra,0xffffe
    80005046:	6a4080e7          	jalr	1700(ra) # 800036e6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000504a:	4601                	li	a2,0
    8000504c:	fb040593          	addi	a1,s0,-80
    80005050:	854a                	mv	a0,s2
    80005052:	fffff097          	auipc	ra,0xfffff
    80005056:	b78080e7          	jalr	-1160(ra) # 80003bca <dirlookup>
    8000505a:	84aa                	mv	s1,a0
    8000505c:	c921                	beqz	a0,800050ac <create+0x94>
    iunlockput(dp);
    8000505e:	854a                	mv	a0,s2
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	8e8080e7          	jalr	-1816(ra) # 80003948 <iunlockput>
    ilock(ip);
    80005068:	8526                	mv	a0,s1
    8000506a:	ffffe097          	auipc	ra,0xffffe
    8000506e:	67c080e7          	jalr	1660(ra) # 800036e6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005072:	2981                	sext.w	s3,s3
    80005074:	4789                	li	a5,2
    80005076:	02f99463          	bne	s3,a5,8000509e <create+0x86>
    8000507a:	0444d783          	lhu	a5,68(s1)
    8000507e:	37f9                	addiw	a5,a5,-2
    80005080:	17c2                	slli	a5,a5,0x30
    80005082:	93c1                	srli	a5,a5,0x30
    80005084:	4705                	li	a4,1
    80005086:	00f76c63          	bltu	a4,a5,8000509e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000508a:	8526                	mv	a0,s1
    8000508c:	60a6                	ld	ra,72(sp)
    8000508e:	6406                	ld	s0,64(sp)
    80005090:	74e2                	ld	s1,56(sp)
    80005092:	7942                	ld	s2,48(sp)
    80005094:	79a2                	ld	s3,40(sp)
    80005096:	7a02                	ld	s4,32(sp)
    80005098:	6ae2                	ld	s5,24(sp)
    8000509a:	6161                	addi	sp,sp,80
    8000509c:	8082                	ret
    iunlockput(ip);
    8000509e:	8526                	mv	a0,s1
    800050a0:	fffff097          	auipc	ra,0xfffff
    800050a4:	8a8080e7          	jalr	-1880(ra) # 80003948 <iunlockput>
    return 0;
    800050a8:	4481                	li	s1,0
    800050aa:	b7c5                	j	8000508a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050ac:	85ce                	mv	a1,s3
    800050ae:	00092503          	lw	a0,0(s2)
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	49c080e7          	jalr	1180(ra) # 8000354e <ialloc>
    800050ba:	84aa                	mv	s1,a0
    800050bc:	c529                	beqz	a0,80005106 <create+0xee>
  ilock(ip);
    800050be:	ffffe097          	auipc	ra,0xffffe
    800050c2:	628080e7          	jalr	1576(ra) # 800036e6 <ilock>
  ip->major = major;
    800050c6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050ca:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050ce:	4785                	li	a5,1
    800050d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800050d4:	8526                	mv	a0,s1
    800050d6:	ffffe097          	auipc	ra,0xffffe
    800050da:	546080e7          	jalr	1350(ra) # 8000361c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050de:	2981                	sext.w	s3,s3
    800050e0:	4785                	li	a5,1
    800050e2:	02f98a63          	beq	s3,a5,80005116 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800050e6:	40d0                	lw	a2,4(s1)
    800050e8:	fb040593          	addi	a1,s0,-80
    800050ec:	854a                	mv	a0,s2
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	cec080e7          	jalr	-788(ra) # 80003dda <dirlink>
    800050f6:	06054b63          	bltz	a0,8000516c <create+0x154>
  iunlockput(dp);
    800050fa:	854a                	mv	a0,s2
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	84c080e7          	jalr	-1972(ra) # 80003948 <iunlockput>
  return ip;
    80005104:	b759                	j	8000508a <create+0x72>
    panic("create: ialloc");
    80005106:	00003517          	auipc	a0,0x3
    8000510a:	68250513          	addi	a0,a0,1666 # 80008788 <syscalls+0x2c0>
    8000510e:	ffffb097          	auipc	ra,0xffffb
    80005112:	430080e7          	jalr	1072(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005116:	04a95783          	lhu	a5,74(s2)
    8000511a:	2785                	addiw	a5,a5,1
    8000511c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005120:	854a                	mv	a0,s2
    80005122:	ffffe097          	auipc	ra,0xffffe
    80005126:	4fa080e7          	jalr	1274(ra) # 8000361c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000512a:	40d0                	lw	a2,4(s1)
    8000512c:	00003597          	auipc	a1,0x3
    80005130:	66c58593          	addi	a1,a1,1644 # 80008798 <syscalls+0x2d0>
    80005134:	8526                	mv	a0,s1
    80005136:	fffff097          	auipc	ra,0xfffff
    8000513a:	ca4080e7          	jalr	-860(ra) # 80003dda <dirlink>
    8000513e:	00054f63          	bltz	a0,8000515c <create+0x144>
    80005142:	00492603          	lw	a2,4(s2)
    80005146:	00003597          	auipc	a1,0x3
    8000514a:	65a58593          	addi	a1,a1,1626 # 800087a0 <syscalls+0x2d8>
    8000514e:	8526                	mv	a0,s1
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	c8a080e7          	jalr	-886(ra) # 80003dda <dirlink>
    80005158:	f80557e3          	bgez	a0,800050e6 <create+0xce>
      panic("create dots");
    8000515c:	00003517          	auipc	a0,0x3
    80005160:	64c50513          	addi	a0,a0,1612 # 800087a8 <syscalls+0x2e0>
    80005164:	ffffb097          	auipc	ra,0xffffb
    80005168:	3da080e7          	jalr	986(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000516c:	00003517          	auipc	a0,0x3
    80005170:	64c50513          	addi	a0,a0,1612 # 800087b8 <syscalls+0x2f0>
    80005174:	ffffb097          	auipc	ra,0xffffb
    80005178:	3ca080e7          	jalr	970(ra) # 8000053e <panic>
    return 0;
    8000517c:	84aa                	mv	s1,a0
    8000517e:	b731                	j	8000508a <create+0x72>

0000000080005180 <sys_dup>:
{
    80005180:	7179                	addi	sp,sp,-48
    80005182:	f406                	sd	ra,40(sp)
    80005184:	f022                	sd	s0,32(sp)
    80005186:	ec26                	sd	s1,24(sp)
    80005188:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000518a:	fd840613          	addi	a2,s0,-40
    8000518e:	4581                	li	a1,0
    80005190:	4501                	li	a0,0
    80005192:	00000097          	auipc	ra,0x0
    80005196:	ddc080e7          	jalr	-548(ra) # 80004f6e <argfd>
    return -1;
    8000519a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000519c:	02054363          	bltz	a0,800051c2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051a0:	fd843503          	ld	a0,-40(s0)
    800051a4:	00000097          	auipc	ra,0x0
    800051a8:	e32080e7          	jalr	-462(ra) # 80004fd6 <fdalloc>
    800051ac:	84aa                	mv	s1,a0
    return -1;
    800051ae:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051b0:	00054963          	bltz	a0,800051c2 <sys_dup+0x42>
  filedup(f);
    800051b4:	fd843503          	ld	a0,-40(s0)
    800051b8:	fffff097          	auipc	ra,0xfffff
    800051bc:	37a080e7          	jalr	890(ra) # 80004532 <filedup>
  return fd;
    800051c0:	87a6                	mv	a5,s1
}
    800051c2:	853e                	mv	a0,a5
    800051c4:	70a2                	ld	ra,40(sp)
    800051c6:	7402                	ld	s0,32(sp)
    800051c8:	64e2                	ld	s1,24(sp)
    800051ca:	6145                	addi	sp,sp,48
    800051cc:	8082                	ret

00000000800051ce <sys_read>:
{
    800051ce:	7179                	addi	sp,sp,-48
    800051d0:	f406                	sd	ra,40(sp)
    800051d2:	f022                	sd	s0,32(sp)
    800051d4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051d6:	fe840613          	addi	a2,s0,-24
    800051da:	4581                	li	a1,0
    800051dc:	4501                	li	a0,0
    800051de:	00000097          	auipc	ra,0x0
    800051e2:	d90080e7          	jalr	-624(ra) # 80004f6e <argfd>
    return -1;
    800051e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e8:	04054163          	bltz	a0,8000522a <sys_read+0x5c>
    800051ec:	fe440593          	addi	a1,s0,-28
    800051f0:	4509                	li	a0,2
    800051f2:	ffffe097          	auipc	ra,0xffffe
    800051f6:	910080e7          	jalr	-1776(ra) # 80002b02 <argint>
    return -1;
    800051fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051fc:	02054763          	bltz	a0,8000522a <sys_read+0x5c>
    80005200:	fd840593          	addi	a1,s0,-40
    80005204:	4505                	li	a0,1
    80005206:	ffffe097          	auipc	ra,0xffffe
    8000520a:	91e080e7          	jalr	-1762(ra) # 80002b24 <argaddr>
    return -1;
    8000520e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005210:	00054d63          	bltz	a0,8000522a <sys_read+0x5c>
  return fileread(f, p, n);
    80005214:	fe442603          	lw	a2,-28(s0)
    80005218:	fd843583          	ld	a1,-40(s0)
    8000521c:	fe843503          	ld	a0,-24(s0)
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	49e080e7          	jalr	1182(ra) # 800046be <fileread>
    80005228:	87aa                	mv	a5,a0
}
    8000522a:	853e                	mv	a0,a5
    8000522c:	70a2                	ld	ra,40(sp)
    8000522e:	7402                	ld	s0,32(sp)
    80005230:	6145                	addi	sp,sp,48
    80005232:	8082                	ret

0000000080005234 <sys_write>:
{
    80005234:	7179                	addi	sp,sp,-48
    80005236:	f406                	sd	ra,40(sp)
    80005238:	f022                	sd	s0,32(sp)
    8000523a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000523c:	fe840613          	addi	a2,s0,-24
    80005240:	4581                	li	a1,0
    80005242:	4501                	li	a0,0
    80005244:	00000097          	auipc	ra,0x0
    80005248:	d2a080e7          	jalr	-726(ra) # 80004f6e <argfd>
    return -1;
    8000524c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000524e:	04054163          	bltz	a0,80005290 <sys_write+0x5c>
    80005252:	fe440593          	addi	a1,s0,-28
    80005256:	4509                	li	a0,2
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	8aa080e7          	jalr	-1878(ra) # 80002b02 <argint>
    return -1;
    80005260:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005262:	02054763          	bltz	a0,80005290 <sys_write+0x5c>
    80005266:	fd840593          	addi	a1,s0,-40
    8000526a:	4505                	li	a0,1
    8000526c:	ffffe097          	auipc	ra,0xffffe
    80005270:	8b8080e7          	jalr	-1864(ra) # 80002b24 <argaddr>
    return -1;
    80005274:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005276:	00054d63          	bltz	a0,80005290 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000527a:	fe442603          	lw	a2,-28(s0)
    8000527e:	fd843583          	ld	a1,-40(s0)
    80005282:	fe843503          	ld	a0,-24(s0)
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	4fa080e7          	jalr	1274(ra) # 80004780 <filewrite>
    8000528e:	87aa                	mv	a5,a0
}
    80005290:	853e                	mv	a0,a5
    80005292:	70a2                	ld	ra,40(sp)
    80005294:	7402                	ld	s0,32(sp)
    80005296:	6145                	addi	sp,sp,48
    80005298:	8082                	ret

000000008000529a <sys_close>:
{
    8000529a:	1101                	addi	sp,sp,-32
    8000529c:	ec06                	sd	ra,24(sp)
    8000529e:	e822                	sd	s0,16(sp)
    800052a0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052a2:	fe040613          	addi	a2,s0,-32
    800052a6:	fec40593          	addi	a1,s0,-20
    800052aa:	4501                	li	a0,0
    800052ac:	00000097          	auipc	ra,0x0
    800052b0:	cc2080e7          	jalr	-830(ra) # 80004f6e <argfd>
    return -1;
    800052b4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052b6:	02054463          	bltz	a0,800052de <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052ba:	ffffc097          	auipc	ra,0xffffc
    800052be:	76c080e7          	jalr	1900(ra) # 80001a26 <myproc>
    800052c2:	fec42783          	lw	a5,-20(s0)
    800052c6:	07e9                	addi	a5,a5,26
    800052c8:	078e                	slli	a5,a5,0x3
    800052ca:	97aa                	add	a5,a5,a0
    800052cc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052d0:	fe043503          	ld	a0,-32(s0)
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	2b0080e7          	jalr	688(ra) # 80004584 <fileclose>
  return 0;
    800052dc:	4781                	li	a5,0
}
    800052de:	853e                	mv	a0,a5
    800052e0:	60e2                	ld	ra,24(sp)
    800052e2:	6442                	ld	s0,16(sp)
    800052e4:	6105                	addi	sp,sp,32
    800052e6:	8082                	ret

00000000800052e8 <sys_fstat>:
{
    800052e8:	1101                	addi	sp,sp,-32
    800052ea:	ec06                	sd	ra,24(sp)
    800052ec:	e822                	sd	s0,16(sp)
    800052ee:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052f0:	fe840613          	addi	a2,s0,-24
    800052f4:	4581                	li	a1,0
    800052f6:	4501                	li	a0,0
    800052f8:	00000097          	auipc	ra,0x0
    800052fc:	c76080e7          	jalr	-906(ra) # 80004f6e <argfd>
    return -1;
    80005300:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005302:	02054563          	bltz	a0,8000532c <sys_fstat+0x44>
    80005306:	fe040593          	addi	a1,s0,-32
    8000530a:	4505                	li	a0,1
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	818080e7          	jalr	-2024(ra) # 80002b24 <argaddr>
    return -1;
    80005314:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005316:	00054b63          	bltz	a0,8000532c <sys_fstat+0x44>
  return filestat(f, st);
    8000531a:	fe043583          	ld	a1,-32(s0)
    8000531e:	fe843503          	ld	a0,-24(s0)
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	32a080e7          	jalr	810(ra) # 8000464c <filestat>
    8000532a:	87aa                	mv	a5,a0
}
    8000532c:	853e                	mv	a0,a5
    8000532e:	60e2                	ld	ra,24(sp)
    80005330:	6442                	ld	s0,16(sp)
    80005332:	6105                	addi	sp,sp,32
    80005334:	8082                	ret

0000000080005336 <sys_link>:
{
    80005336:	7169                	addi	sp,sp,-304
    80005338:	f606                	sd	ra,296(sp)
    8000533a:	f222                	sd	s0,288(sp)
    8000533c:	ee26                	sd	s1,280(sp)
    8000533e:	ea4a                	sd	s2,272(sp)
    80005340:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005342:	08000613          	li	a2,128
    80005346:	ed040593          	addi	a1,s0,-304
    8000534a:	4501                	li	a0,0
    8000534c:	ffffd097          	auipc	ra,0xffffd
    80005350:	7fa080e7          	jalr	2042(ra) # 80002b46 <argstr>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005356:	10054e63          	bltz	a0,80005472 <sys_link+0x13c>
    8000535a:	08000613          	li	a2,128
    8000535e:	f5040593          	addi	a1,s0,-176
    80005362:	4505                	li	a0,1
    80005364:	ffffd097          	auipc	ra,0xffffd
    80005368:	7e2080e7          	jalr	2018(ra) # 80002b46 <argstr>
    return -1;
    8000536c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000536e:	10054263          	bltz	a0,80005472 <sys_link+0x13c>
  begin_op();
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	d46080e7          	jalr	-698(ra) # 800040b8 <begin_op>
  if((ip = namei(old)) == 0){
    8000537a:	ed040513          	addi	a0,s0,-304
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	b1e080e7          	jalr	-1250(ra) # 80003e9c <namei>
    80005386:	84aa                	mv	s1,a0
    80005388:	c551                	beqz	a0,80005414 <sys_link+0xde>
  ilock(ip);
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	35c080e7          	jalr	860(ra) # 800036e6 <ilock>
  if(ip->type == T_DIR){
    80005392:	04449703          	lh	a4,68(s1)
    80005396:	4785                	li	a5,1
    80005398:	08f70463          	beq	a4,a5,80005420 <sys_link+0xea>
  ip->nlink++;
    8000539c:	04a4d783          	lhu	a5,74(s1)
    800053a0:	2785                	addiw	a5,a5,1
    800053a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053a6:	8526                	mv	a0,s1
    800053a8:	ffffe097          	auipc	ra,0xffffe
    800053ac:	274080e7          	jalr	628(ra) # 8000361c <iupdate>
  iunlock(ip);
    800053b0:	8526                	mv	a0,s1
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	3f6080e7          	jalr	1014(ra) # 800037a8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053ba:	fd040593          	addi	a1,s0,-48
    800053be:	f5040513          	addi	a0,s0,-176
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	af8080e7          	jalr	-1288(ra) # 80003eba <nameiparent>
    800053ca:	892a                	mv	s2,a0
    800053cc:	c935                	beqz	a0,80005440 <sys_link+0x10a>
  ilock(dp);
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	318080e7          	jalr	792(ra) # 800036e6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053d6:	00092703          	lw	a4,0(s2)
    800053da:	409c                	lw	a5,0(s1)
    800053dc:	04f71d63          	bne	a4,a5,80005436 <sys_link+0x100>
    800053e0:	40d0                	lw	a2,4(s1)
    800053e2:	fd040593          	addi	a1,s0,-48
    800053e6:	854a                	mv	a0,s2
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	9f2080e7          	jalr	-1550(ra) # 80003dda <dirlink>
    800053f0:	04054363          	bltz	a0,80005436 <sys_link+0x100>
  iunlockput(dp);
    800053f4:	854a                	mv	a0,s2
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	552080e7          	jalr	1362(ra) # 80003948 <iunlockput>
  iput(ip);
    800053fe:	8526                	mv	a0,s1
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	4a0080e7          	jalr	1184(ra) # 800038a0 <iput>
  end_op();
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	d30080e7          	jalr	-720(ra) # 80004138 <end_op>
  return 0;
    80005410:	4781                	li	a5,0
    80005412:	a085                	j	80005472 <sys_link+0x13c>
    end_op();
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	d24080e7          	jalr	-732(ra) # 80004138 <end_op>
    return -1;
    8000541c:	57fd                	li	a5,-1
    8000541e:	a891                	j	80005472 <sys_link+0x13c>
    iunlockput(ip);
    80005420:	8526                	mv	a0,s1
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	526080e7          	jalr	1318(ra) # 80003948 <iunlockput>
    end_op();
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	d0e080e7          	jalr	-754(ra) # 80004138 <end_op>
    return -1;
    80005432:	57fd                	li	a5,-1
    80005434:	a83d                	j	80005472 <sys_link+0x13c>
    iunlockput(dp);
    80005436:	854a                	mv	a0,s2
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	510080e7          	jalr	1296(ra) # 80003948 <iunlockput>
  ilock(ip);
    80005440:	8526                	mv	a0,s1
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	2a4080e7          	jalr	676(ra) # 800036e6 <ilock>
  ip->nlink--;
    8000544a:	04a4d783          	lhu	a5,74(s1)
    8000544e:	37fd                	addiw	a5,a5,-1
    80005450:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	1c6080e7          	jalr	454(ra) # 8000361c <iupdate>
  iunlockput(ip);
    8000545e:	8526                	mv	a0,s1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	4e8080e7          	jalr	1256(ra) # 80003948 <iunlockput>
  end_op();
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	cd0080e7          	jalr	-816(ra) # 80004138 <end_op>
  return -1;
    80005470:	57fd                	li	a5,-1
}
    80005472:	853e                	mv	a0,a5
    80005474:	70b2                	ld	ra,296(sp)
    80005476:	7412                	ld	s0,288(sp)
    80005478:	64f2                	ld	s1,280(sp)
    8000547a:	6952                	ld	s2,272(sp)
    8000547c:	6155                	addi	sp,sp,304
    8000547e:	8082                	ret

0000000080005480 <sys_unlink>:
{
    80005480:	7151                	addi	sp,sp,-240
    80005482:	f586                	sd	ra,232(sp)
    80005484:	f1a2                	sd	s0,224(sp)
    80005486:	eda6                	sd	s1,216(sp)
    80005488:	e9ca                	sd	s2,208(sp)
    8000548a:	e5ce                	sd	s3,200(sp)
    8000548c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000548e:	08000613          	li	a2,128
    80005492:	f3040593          	addi	a1,s0,-208
    80005496:	4501                	li	a0,0
    80005498:	ffffd097          	auipc	ra,0xffffd
    8000549c:	6ae080e7          	jalr	1710(ra) # 80002b46 <argstr>
    800054a0:	18054163          	bltz	a0,80005622 <sys_unlink+0x1a2>
  begin_op();
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	c14080e7          	jalr	-1004(ra) # 800040b8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054ac:	fb040593          	addi	a1,s0,-80
    800054b0:	f3040513          	addi	a0,s0,-208
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	a06080e7          	jalr	-1530(ra) # 80003eba <nameiparent>
    800054bc:	84aa                	mv	s1,a0
    800054be:	c979                	beqz	a0,80005594 <sys_unlink+0x114>
  ilock(dp);
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	226080e7          	jalr	550(ra) # 800036e6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054c8:	00003597          	auipc	a1,0x3
    800054cc:	2d058593          	addi	a1,a1,720 # 80008798 <syscalls+0x2d0>
    800054d0:	fb040513          	addi	a0,s0,-80
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	6dc080e7          	jalr	1756(ra) # 80003bb0 <namecmp>
    800054dc:	14050a63          	beqz	a0,80005630 <sys_unlink+0x1b0>
    800054e0:	00003597          	auipc	a1,0x3
    800054e4:	2c058593          	addi	a1,a1,704 # 800087a0 <syscalls+0x2d8>
    800054e8:	fb040513          	addi	a0,s0,-80
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	6c4080e7          	jalr	1732(ra) # 80003bb0 <namecmp>
    800054f4:	12050e63          	beqz	a0,80005630 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054f8:	f2c40613          	addi	a2,s0,-212
    800054fc:	fb040593          	addi	a1,s0,-80
    80005500:	8526                	mv	a0,s1
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	6c8080e7          	jalr	1736(ra) # 80003bca <dirlookup>
    8000550a:	892a                	mv	s2,a0
    8000550c:	12050263          	beqz	a0,80005630 <sys_unlink+0x1b0>
  ilock(ip);
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	1d6080e7          	jalr	470(ra) # 800036e6 <ilock>
  if(ip->nlink < 1)
    80005518:	04a91783          	lh	a5,74(s2)
    8000551c:	08f05263          	blez	a5,800055a0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005520:	04491703          	lh	a4,68(s2)
    80005524:	4785                	li	a5,1
    80005526:	08f70563          	beq	a4,a5,800055b0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000552a:	4641                	li	a2,16
    8000552c:	4581                	li	a1,0
    8000552e:	fc040513          	addi	a0,s0,-64
    80005532:	ffffb097          	auipc	ra,0xffffb
    80005536:	7ae080e7          	jalr	1966(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000553a:	4741                	li	a4,16
    8000553c:	f2c42683          	lw	a3,-212(s0)
    80005540:	fc040613          	addi	a2,s0,-64
    80005544:	4581                	li	a1,0
    80005546:	8526                	mv	a0,s1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	54a080e7          	jalr	1354(ra) # 80003a92 <writei>
    80005550:	47c1                	li	a5,16
    80005552:	0af51563          	bne	a0,a5,800055fc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005556:	04491703          	lh	a4,68(s2)
    8000555a:	4785                	li	a5,1
    8000555c:	0af70863          	beq	a4,a5,8000560c <sys_unlink+0x18c>
  iunlockput(dp);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	3e6080e7          	jalr	998(ra) # 80003948 <iunlockput>
  ip->nlink--;
    8000556a:	04a95783          	lhu	a5,74(s2)
    8000556e:	37fd                	addiw	a5,a5,-1
    80005570:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005574:	854a                	mv	a0,s2
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	0a6080e7          	jalr	166(ra) # 8000361c <iupdate>
  iunlockput(ip);
    8000557e:	854a                	mv	a0,s2
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	3c8080e7          	jalr	968(ra) # 80003948 <iunlockput>
  end_op();
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	bb0080e7          	jalr	-1104(ra) # 80004138 <end_op>
  return 0;
    80005590:	4501                	li	a0,0
    80005592:	a84d                	j	80005644 <sys_unlink+0x1c4>
    end_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	ba4080e7          	jalr	-1116(ra) # 80004138 <end_op>
    return -1;
    8000559c:	557d                	li	a0,-1
    8000559e:	a05d                	j	80005644 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055a0:	00003517          	auipc	a0,0x3
    800055a4:	22850513          	addi	a0,a0,552 # 800087c8 <syscalls+0x300>
    800055a8:	ffffb097          	auipc	ra,0xffffb
    800055ac:	f96080e7          	jalr	-106(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055b0:	04c92703          	lw	a4,76(s2)
    800055b4:	02000793          	li	a5,32
    800055b8:	f6e7f9e3          	bgeu	a5,a4,8000552a <sys_unlink+0xaa>
    800055bc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055c0:	4741                	li	a4,16
    800055c2:	86ce                	mv	a3,s3
    800055c4:	f1840613          	addi	a2,s0,-232
    800055c8:	4581                	li	a1,0
    800055ca:	854a                	mv	a0,s2
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	3ce080e7          	jalr	974(ra) # 8000399a <readi>
    800055d4:	47c1                	li	a5,16
    800055d6:	00f51b63          	bne	a0,a5,800055ec <sys_unlink+0x16c>
    if(de.inum != 0)
    800055da:	f1845783          	lhu	a5,-232(s0)
    800055de:	e7a1                	bnez	a5,80005626 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055e0:	29c1                	addiw	s3,s3,16
    800055e2:	04c92783          	lw	a5,76(s2)
    800055e6:	fcf9ede3          	bltu	s3,a5,800055c0 <sys_unlink+0x140>
    800055ea:	b781                	j	8000552a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055ec:	00003517          	auipc	a0,0x3
    800055f0:	1f450513          	addi	a0,a0,500 # 800087e0 <syscalls+0x318>
    800055f4:	ffffb097          	auipc	ra,0xffffb
    800055f8:	f4a080e7          	jalr	-182(ra) # 8000053e <panic>
    panic("unlink: writei");
    800055fc:	00003517          	auipc	a0,0x3
    80005600:	1fc50513          	addi	a0,a0,508 # 800087f8 <syscalls+0x330>
    80005604:	ffffb097          	auipc	ra,0xffffb
    80005608:	f3a080e7          	jalr	-198(ra) # 8000053e <panic>
    dp->nlink--;
    8000560c:	04a4d783          	lhu	a5,74(s1)
    80005610:	37fd                	addiw	a5,a5,-1
    80005612:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005616:	8526                	mv	a0,s1
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	004080e7          	jalr	4(ra) # 8000361c <iupdate>
    80005620:	b781                	j	80005560 <sys_unlink+0xe0>
    return -1;
    80005622:	557d                	li	a0,-1
    80005624:	a005                	j	80005644 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005626:	854a                	mv	a0,s2
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	320080e7          	jalr	800(ra) # 80003948 <iunlockput>
  iunlockput(dp);
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	316080e7          	jalr	790(ra) # 80003948 <iunlockput>
  end_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	afe080e7          	jalr	-1282(ra) # 80004138 <end_op>
  return -1;
    80005642:	557d                	li	a0,-1
}
    80005644:	70ae                	ld	ra,232(sp)
    80005646:	740e                	ld	s0,224(sp)
    80005648:	64ee                	ld	s1,216(sp)
    8000564a:	694e                	ld	s2,208(sp)
    8000564c:	69ae                	ld	s3,200(sp)
    8000564e:	616d                	addi	sp,sp,240
    80005650:	8082                	ret

0000000080005652 <sys_open>:

uint64
sys_open(void)
{
    80005652:	7131                	addi	sp,sp,-192
    80005654:	fd06                	sd	ra,184(sp)
    80005656:	f922                	sd	s0,176(sp)
    80005658:	f526                	sd	s1,168(sp)
    8000565a:	f14a                	sd	s2,160(sp)
    8000565c:	ed4e                	sd	s3,152(sp)
    8000565e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005660:	08000613          	li	a2,128
    80005664:	f5040593          	addi	a1,s0,-176
    80005668:	4501                	li	a0,0
    8000566a:	ffffd097          	auipc	ra,0xffffd
    8000566e:	4dc080e7          	jalr	1244(ra) # 80002b46 <argstr>
    return -1;
    80005672:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005674:	0c054163          	bltz	a0,80005736 <sys_open+0xe4>
    80005678:	f4c40593          	addi	a1,s0,-180
    8000567c:	4505                	li	a0,1
    8000567e:	ffffd097          	auipc	ra,0xffffd
    80005682:	484080e7          	jalr	1156(ra) # 80002b02 <argint>
    80005686:	0a054863          	bltz	a0,80005736 <sys_open+0xe4>

  begin_op();
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	a2e080e7          	jalr	-1490(ra) # 800040b8 <begin_op>

  if(omode & O_CREATE){
    80005692:	f4c42783          	lw	a5,-180(s0)
    80005696:	2007f793          	andi	a5,a5,512
    8000569a:	cbdd                	beqz	a5,80005750 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000569c:	4681                	li	a3,0
    8000569e:	4601                	li	a2,0
    800056a0:	4589                	li	a1,2
    800056a2:	f5040513          	addi	a0,s0,-176
    800056a6:	00000097          	auipc	ra,0x0
    800056aa:	972080e7          	jalr	-1678(ra) # 80005018 <create>
    800056ae:	892a                	mv	s2,a0
    if(ip == 0){
    800056b0:	c959                	beqz	a0,80005746 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056b2:	04491703          	lh	a4,68(s2)
    800056b6:	478d                	li	a5,3
    800056b8:	00f71763          	bne	a4,a5,800056c6 <sys_open+0x74>
    800056bc:	04695703          	lhu	a4,70(s2)
    800056c0:	47a5                	li	a5,9
    800056c2:	0ce7ec63          	bltu	a5,a4,8000579a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	e02080e7          	jalr	-510(ra) # 800044c8 <filealloc>
    800056ce:	89aa                	mv	s3,a0
    800056d0:	10050263          	beqz	a0,800057d4 <sys_open+0x182>
    800056d4:	00000097          	auipc	ra,0x0
    800056d8:	902080e7          	jalr	-1790(ra) # 80004fd6 <fdalloc>
    800056dc:	84aa                	mv	s1,a0
    800056de:	0e054663          	bltz	a0,800057ca <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056e2:	04491703          	lh	a4,68(s2)
    800056e6:	478d                	li	a5,3
    800056e8:	0cf70463          	beq	a4,a5,800057b0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056ec:	4789                	li	a5,2
    800056ee:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056f2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056f6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056fa:	f4c42783          	lw	a5,-180(s0)
    800056fe:	0017c713          	xori	a4,a5,1
    80005702:	8b05                	andi	a4,a4,1
    80005704:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005708:	0037f713          	andi	a4,a5,3
    8000570c:	00e03733          	snez	a4,a4
    80005710:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005714:	4007f793          	andi	a5,a5,1024
    80005718:	c791                	beqz	a5,80005724 <sys_open+0xd2>
    8000571a:	04491703          	lh	a4,68(s2)
    8000571e:	4789                	li	a5,2
    80005720:	08f70f63          	beq	a4,a5,800057be <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005724:	854a                	mv	a0,s2
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	082080e7          	jalr	130(ra) # 800037a8 <iunlock>
  end_op();
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	a0a080e7          	jalr	-1526(ra) # 80004138 <end_op>

  return fd;
}
    80005736:	8526                	mv	a0,s1
    80005738:	70ea                	ld	ra,184(sp)
    8000573a:	744a                	ld	s0,176(sp)
    8000573c:	74aa                	ld	s1,168(sp)
    8000573e:	790a                	ld	s2,160(sp)
    80005740:	69ea                	ld	s3,152(sp)
    80005742:	6129                	addi	sp,sp,192
    80005744:	8082                	ret
      end_op();
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	9f2080e7          	jalr	-1550(ra) # 80004138 <end_op>
      return -1;
    8000574e:	b7e5                	j	80005736 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005750:	f5040513          	addi	a0,s0,-176
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	748080e7          	jalr	1864(ra) # 80003e9c <namei>
    8000575c:	892a                	mv	s2,a0
    8000575e:	c905                	beqz	a0,8000578e <sys_open+0x13c>
    ilock(ip);
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	f86080e7          	jalr	-122(ra) # 800036e6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005768:	04491703          	lh	a4,68(s2)
    8000576c:	4785                	li	a5,1
    8000576e:	f4f712e3          	bne	a4,a5,800056b2 <sys_open+0x60>
    80005772:	f4c42783          	lw	a5,-180(s0)
    80005776:	dba1                	beqz	a5,800056c6 <sys_open+0x74>
      iunlockput(ip);
    80005778:	854a                	mv	a0,s2
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	1ce080e7          	jalr	462(ra) # 80003948 <iunlockput>
      end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	9b6080e7          	jalr	-1610(ra) # 80004138 <end_op>
      return -1;
    8000578a:	54fd                	li	s1,-1
    8000578c:	b76d                	j	80005736 <sys_open+0xe4>
      end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	9aa080e7          	jalr	-1622(ra) # 80004138 <end_op>
      return -1;
    80005796:	54fd                	li	s1,-1
    80005798:	bf79                	j	80005736 <sys_open+0xe4>
    iunlockput(ip);
    8000579a:	854a                	mv	a0,s2
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	1ac080e7          	jalr	428(ra) # 80003948 <iunlockput>
    end_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	994080e7          	jalr	-1644(ra) # 80004138 <end_op>
    return -1;
    800057ac:	54fd                	li	s1,-1
    800057ae:	b761                	j	80005736 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057b0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057b4:	04691783          	lh	a5,70(s2)
    800057b8:	02f99223          	sh	a5,36(s3)
    800057bc:	bf2d                	j	800056f6 <sys_open+0xa4>
    itrunc(ip);
    800057be:	854a                	mv	a0,s2
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	034080e7          	jalr	52(ra) # 800037f4 <itrunc>
    800057c8:	bfb1                	j	80005724 <sys_open+0xd2>
      fileclose(f);
    800057ca:	854e                	mv	a0,s3
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	db8080e7          	jalr	-584(ra) # 80004584 <fileclose>
    iunlockput(ip);
    800057d4:	854a                	mv	a0,s2
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	172080e7          	jalr	370(ra) # 80003948 <iunlockput>
    end_op();
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	95a080e7          	jalr	-1702(ra) # 80004138 <end_op>
    return -1;
    800057e6:	54fd                	li	s1,-1
    800057e8:	b7b9                	j	80005736 <sys_open+0xe4>

00000000800057ea <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057ea:	7175                	addi	sp,sp,-144
    800057ec:	e506                	sd	ra,136(sp)
    800057ee:	e122                	sd	s0,128(sp)
    800057f0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	8c6080e7          	jalr	-1850(ra) # 800040b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057fa:	08000613          	li	a2,128
    800057fe:	f7040593          	addi	a1,s0,-144
    80005802:	4501                	li	a0,0
    80005804:	ffffd097          	auipc	ra,0xffffd
    80005808:	342080e7          	jalr	834(ra) # 80002b46 <argstr>
    8000580c:	02054963          	bltz	a0,8000583e <sys_mkdir+0x54>
    80005810:	4681                	li	a3,0
    80005812:	4601                	li	a2,0
    80005814:	4585                	li	a1,1
    80005816:	f7040513          	addi	a0,s0,-144
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	7fe080e7          	jalr	2046(ra) # 80005018 <create>
    80005822:	cd11                	beqz	a0,8000583e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	124080e7          	jalr	292(ra) # 80003948 <iunlockput>
  end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	90c080e7          	jalr	-1780(ra) # 80004138 <end_op>
  return 0;
    80005834:	4501                	li	a0,0
}
    80005836:	60aa                	ld	ra,136(sp)
    80005838:	640a                	ld	s0,128(sp)
    8000583a:	6149                	addi	sp,sp,144
    8000583c:	8082                	ret
    end_op();
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	8fa080e7          	jalr	-1798(ra) # 80004138 <end_op>
    return -1;
    80005846:	557d                	li	a0,-1
    80005848:	b7fd                	j	80005836 <sys_mkdir+0x4c>

000000008000584a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000584a:	7135                	addi	sp,sp,-160
    8000584c:	ed06                	sd	ra,152(sp)
    8000584e:	e922                	sd	s0,144(sp)
    80005850:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	866080e7          	jalr	-1946(ra) # 800040b8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000585a:	08000613          	li	a2,128
    8000585e:	f7040593          	addi	a1,s0,-144
    80005862:	4501                	li	a0,0
    80005864:	ffffd097          	auipc	ra,0xffffd
    80005868:	2e2080e7          	jalr	738(ra) # 80002b46 <argstr>
    8000586c:	04054a63          	bltz	a0,800058c0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005870:	f6c40593          	addi	a1,s0,-148
    80005874:	4505                	li	a0,1
    80005876:	ffffd097          	auipc	ra,0xffffd
    8000587a:	28c080e7          	jalr	652(ra) # 80002b02 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000587e:	04054163          	bltz	a0,800058c0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005882:	f6840593          	addi	a1,s0,-152
    80005886:	4509                	li	a0,2
    80005888:	ffffd097          	auipc	ra,0xffffd
    8000588c:	27a080e7          	jalr	634(ra) # 80002b02 <argint>
     argint(1, &major) < 0 ||
    80005890:	02054863          	bltz	a0,800058c0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005894:	f6841683          	lh	a3,-152(s0)
    80005898:	f6c41603          	lh	a2,-148(s0)
    8000589c:	458d                	li	a1,3
    8000589e:	f7040513          	addi	a0,s0,-144
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	776080e7          	jalr	1910(ra) # 80005018 <create>
     argint(2, &minor) < 0 ||
    800058aa:	c919                	beqz	a0,800058c0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	09c080e7          	jalr	156(ra) # 80003948 <iunlockput>
  end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	884080e7          	jalr	-1916(ra) # 80004138 <end_op>
  return 0;
    800058bc:	4501                	li	a0,0
    800058be:	a031                	j	800058ca <sys_mknod+0x80>
    end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	878080e7          	jalr	-1928(ra) # 80004138 <end_op>
    return -1;
    800058c8:	557d                	li	a0,-1
}
    800058ca:	60ea                	ld	ra,152(sp)
    800058cc:	644a                	ld	s0,144(sp)
    800058ce:	610d                	addi	sp,sp,160
    800058d0:	8082                	ret

00000000800058d2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058d2:	7135                	addi	sp,sp,-160
    800058d4:	ed06                	sd	ra,152(sp)
    800058d6:	e922                	sd	s0,144(sp)
    800058d8:	e526                	sd	s1,136(sp)
    800058da:	e14a                	sd	s2,128(sp)
    800058dc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058de:	ffffc097          	auipc	ra,0xffffc
    800058e2:	148080e7          	jalr	328(ra) # 80001a26 <myproc>
    800058e6:	892a                	mv	s2,a0
  
  begin_op();
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	7d0080e7          	jalr	2000(ra) # 800040b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058f0:	08000613          	li	a2,128
    800058f4:	f6040593          	addi	a1,s0,-160
    800058f8:	4501                	li	a0,0
    800058fa:	ffffd097          	auipc	ra,0xffffd
    800058fe:	24c080e7          	jalr	588(ra) # 80002b46 <argstr>
    80005902:	04054b63          	bltz	a0,80005958 <sys_chdir+0x86>
    80005906:	f6040513          	addi	a0,s0,-160
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	592080e7          	jalr	1426(ra) # 80003e9c <namei>
    80005912:	84aa                	mv	s1,a0
    80005914:	c131                	beqz	a0,80005958 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	dd0080e7          	jalr	-560(ra) # 800036e6 <ilock>
  if(ip->type != T_DIR){
    8000591e:	04449703          	lh	a4,68(s1)
    80005922:	4785                	li	a5,1
    80005924:	04f71063          	bne	a4,a5,80005964 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005928:	8526                	mv	a0,s1
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	e7e080e7          	jalr	-386(ra) # 800037a8 <iunlock>
  iput(p->cwd);
    80005932:	15093503          	ld	a0,336(s2)
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	f6a080e7          	jalr	-150(ra) # 800038a0 <iput>
  end_op();
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	7fa080e7          	jalr	2042(ra) # 80004138 <end_op>
  p->cwd = ip;
    80005946:	14993823          	sd	s1,336(s2)
  return 0;
    8000594a:	4501                	li	a0,0
}
    8000594c:	60ea                	ld	ra,152(sp)
    8000594e:	644a                	ld	s0,144(sp)
    80005950:	64aa                	ld	s1,136(sp)
    80005952:	690a                	ld	s2,128(sp)
    80005954:	610d                	addi	sp,sp,160
    80005956:	8082                	ret
    end_op();
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	7e0080e7          	jalr	2016(ra) # 80004138 <end_op>
    return -1;
    80005960:	557d                	li	a0,-1
    80005962:	b7ed                	j	8000594c <sys_chdir+0x7a>
    iunlockput(ip);
    80005964:	8526                	mv	a0,s1
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	fe2080e7          	jalr	-30(ra) # 80003948 <iunlockput>
    end_op();
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	7ca080e7          	jalr	1994(ra) # 80004138 <end_op>
    return -1;
    80005976:	557d                	li	a0,-1
    80005978:	bfd1                	j	8000594c <sys_chdir+0x7a>

000000008000597a <sys_exec>:

uint64
sys_exec(void)
{
    8000597a:	7145                	addi	sp,sp,-464
    8000597c:	e786                	sd	ra,456(sp)
    8000597e:	e3a2                	sd	s0,448(sp)
    80005980:	ff26                	sd	s1,440(sp)
    80005982:	fb4a                	sd	s2,432(sp)
    80005984:	f74e                	sd	s3,424(sp)
    80005986:	f352                	sd	s4,416(sp)
    80005988:	ef56                	sd	s5,408(sp)
    8000598a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000598c:	08000613          	li	a2,128
    80005990:	f4040593          	addi	a1,s0,-192
    80005994:	4501                	li	a0,0
    80005996:	ffffd097          	auipc	ra,0xffffd
    8000599a:	1b0080e7          	jalr	432(ra) # 80002b46 <argstr>
    return -1;
    8000599e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059a0:	0c054a63          	bltz	a0,80005a74 <sys_exec+0xfa>
    800059a4:	e3840593          	addi	a1,s0,-456
    800059a8:	4505                	li	a0,1
    800059aa:	ffffd097          	auipc	ra,0xffffd
    800059ae:	17a080e7          	jalr	378(ra) # 80002b24 <argaddr>
    800059b2:	0c054163          	bltz	a0,80005a74 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059b6:	10000613          	li	a2,256
    800059ba:	4581                	li	a1,0
    800059bc:	e4040513          	addi	a0,s0,-448
    800059c0:	ffffb097          	auipc	ra,0xffffb
    800059c4:	320080e7          	jalr	800(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059c8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059cc:	89a6                	mv	s3,s1
    800059ce:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059d0:	02000a13          	li	s4,32
    800059d4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059d8:	00391513          	slli	a0,s2,0x3
    800059dc:	e3040593          	addi	a1,s0,-464
    800059e0:	e3843783          	ld	a5,-456(s0)
    800059e4:	953e                	add	a0,a0,a5
    800059e6:	ffffd097          	auipc	ra,0xffffd
    800059ea:	082080e7          	jalr	130(ra) # 80002a68 <fetchaddr>
    800059ee:	02054a63          	bltz	a0,80005a22 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059f2:	e3043783          	ld	a5,-464(s0)
    800059f6:	c3b9                	beqz	a5,80005a3c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059f8:	ffffb097          	auipc	ra,0xffffb
    800059fc:	0fc080e7          	jalr	252(ra) # 80000af4 <kalloc>
    80005a00:	85aa                	mv	a1,a0
    80005a02:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a06:	cd11                	beqz	a0,80005a22 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a08:	6605                	lui	a2,0x1
    80005a0a:	e3043503          	ld	a0,-464(s0)
    80005a0e:	ffffd097          	auipc	ra,0xffffd
    80005a12:	0ac080e7          	jalr	172(ra) # 80002aba <fetchstr>
    80005a16:	00054663          	bltz	a0,80005a22 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a1a:	0905                	addi	s2,s2,1
    80005a1c:	09a1                	addi	s3,s3,8
    80005a1e:	fb491be3          	bne	s2,s4,800059d4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a22:	10048913          	addi	s2,s1,256
    80005a26:	6088                	ld	a0,0(s1)
    80005a28:	c529                	beqz	a0,80005a72 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a2a:	ffffb097          	auipc	ra,0xffffb
    80005a2e:	fce080e7          	jalr	-50(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a32:	04a1                	addi	s1,s1,8
    80005a34:	ff2499e3          	bne	s1,s2,80005a26 <sys_exec+0xac>
  return -1;
    80005a38:	597d                	li	s2,-1
    80005a3a:	a82d                	j	80005a74 <sys_exec+0xfa>
      argv[i] = 0;
    80005a3c:	0a8e                	slli	s5,s5,0x3
    80005a3e:	fc040793          	addi	a5,s0,-64
    80005a42:	9abe                	add	s5,s5,a5
    80005a44:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a48:	e4040593          	addi	a1,s0,-448
    80005a4c:	f4040513          	addi	a0,s0,-192
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	194080e7          	jalr	404(ra) # 80004be4 <exec>
    80005a58:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a5a:	10048993          	addi	s3,s1,256
    80005a5e:	6088                	ld	a0,0(s1)
    80005a60:	c911                	beqz	a0,80005a74 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a62:	ffffb097          	auipc	ra,0xffffb
    80005a66:	f96080e7          	jalr	-106(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a6a:	04a1                	addi	s1,s1,8
    80005a6c:	ff3499e3          	bne	s1,s3,80005a5e <sys_exec+0xe4>
    80005a70:	a011                	j	80005a74 <sys_exec+0xfa>
  return -1;
    80005a72:	597d                	li	s2,-1
}
    80005a74:	854a                	mv	a0,s2
    80005a76:	60be                	ld	ra,456(sp)
    80005a78:	641e                	ld	s0,448(sp)
    80005a7a:	74fa                	ld	s1,440(sp)
    80005a7c:	795a                	ld	s2,432(sp)
    80005a7e:	79ba                	ld	s3,424(sp)
    80005a80:	7a1a                	ld	s4,416(sp)
    80005a82:	6afa                	ld	s5,408(sp)
    80005a84:	6179                	addi	sp,sp,464
    80005a86:	8082                	ret

0000000080005a88 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a88:	7139                	addi	sp,sp,-64
    80005a8a:	fc06                	sd	ra,56(sp)
    80005a8c:	f822                	sd	s0,48(sp)
    80005a8e:	f426                	sd	s1,40(sp)
    80005a90:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a92:	ffffc097          	auipc	ra,0xffffc
    80005a96:	f94080e7          	jalr	-108(ra) # 80001a26 <myproc>
    80005a9a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a9c:	fd840593          	addi	a1,s0,-40
    80005aa0:	4501                	li	a0,0
    80005aa2:	ffffd097          	auipc	ra,0xffffd
    80005aa6:	082080e7          	jalr	130(ra) # 80002b24 <argaddr>
    return -1;
    80005aaa:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005aac:	0e054063          	bltz	a0,80005b8c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ab0:	fc840593          	addi	a1,s0,-56
    80005ab4:	fd040513          	addi	a0,s0,-48
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	dfc080e7          	jalr	-516(ra) # 800048b4 <pipealloc>
    return -1;
    80005ac0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ac2:	0c054563          	bltz	a0,80005b8c <sys_pipe+0x104>
  fd0 = -1;
    80005ac6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005aca:	fd043503          	ld	a0,-48(s0)
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	508080e7          	jalr	1288(ra) # 80004fd6 <fdalloc>
    80005ad6:	fca42223          	sw	a0,-60(s0)
    80005ada:	08054c63          	bltz	a0,80005b72 <sys_pipe+0xea>
    80005ade:	fc843503          	ld	a0,-56(s0)
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	4f4080e7          	jalr	1268(ra) # 80004fd6 <fdalloc>
    80005aea:	fca42023          	sw	a0,-64(s0)
    80005aee:	06054863          	bltz	a0,80005b5e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005af2:	4691                	li	a3,4
    80005af4:	fc440613          	addi	a2,s0,-60
    80005af8:	fd843583          	ld	a1,-40(s0)
    80005afc:	68a8                	ld	a0,80(s1)
    80005afe:	ffffc097          	auipc	ra,0xffffc
    80005b02:	b74080e7          	jalr	-1164(ra) # 80001672 <copyout>
    80005b06:	02054063          	bltz	a0,80005b26 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b0a:	4691                	li	a3,4
    80005b0c:	fc040613          	addi	a2,s0,-64
    80005b10:	fd843583          	ld	a1,-40(s0)
    80005b14:	0591                	addi	a1,a1,4
    80005b16:	68a8                	ld	a0,80(s1)
    80005b18:	ffffc097          	auipc	ra,0xffffc
    80005b1c:	b5a080e7          	jalr	-1190(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b20:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b22:	06055563          	bgez	a0,80005b8c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b26:	fc442783          	lw	a5,-60(s0)
    80005b2a:	07e9                	addi	a5,a5,26
    80005b2c:	078e                	slli	a5,a5,0x3
    80005b2e:	97a6                	add	a5,a5,s1
    80005b30:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b34:	fc042503          	lw	a0,-64(s0)
    80005b38:	0569                	addi	a0,a0,26
    80005b3a:	050e                	slli	a0,a0,0x3
    80005b3c:	9526                	add	a0,a0,s1
    80005b3e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b42:	fd043503          	ld	a0,-48(s0)
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	a3e080e7          	jalr	-1474(ra) # 80004584 <fileclose>
    fileclose(wf);
    80005b4e:	fc843503          	ld	a0,-56(s0)
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	a32080e7          	jalr	-1486(ra) # 80004584 <fileclose>
    return -1;
    80005b5a:	57fd                	li	a5,-1
    80005b5c:	a805                	j	80005b8c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b5e:	fc442783          	lw	a5,-60(s0)
    80005b62:	0007c863          	bltz	a5,80005b72 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b66:	01a78513          	addi	a0,a5,26
    80005b6a:	050e                	slli	a0,a0,0x3
    80005b6c:	9526                	add	a0,a0,s1
    80005b6e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b72:	fd043503          	ld	a0,-48(s0)
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	a0e080e7          	jalr	-1522(ra) # 80004584 <fileclose>
    fileclose(wf);
    80005b7e:	fc843503          	ld	a0,-56(s0)
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	a02080e7          	jalr	-1534(ra) # 80004584 <fileclose>
    return -1;
    80005b8a:	57fd                	li	a5,-1
}
    80005b8c:	853e                	mv	a0,a5
    80005b8e:	70e2                	ld	ra,56(sp)
    80005b90:	7442                	ld	s0,48(sp)
    80005b92:	74a2                	ld	s1,40(sp)
    80005b94:	6121                	addi	sp,sp,64
    80005b96:	8082                	ret
	...

0000000080005ba0 <kernelvec>:
    80005ba0:	7111                	addi	sp,sp,-256
    80005ba2:	e006                	sd	ra,0(sp)
    80005ba4:	e40a                	sd	sp,8(sp)
    80005ba6:	e80e                	sd	gp,16(sp)
    80005ba8:	ec12                	sd	tp,24(sp)
    80005baa:	f016                	sd	t0,32(sp)
    80005bac:	f41a                	sd	t1,40(sp)
    80005bae:	f81e                	sd	t2,48(sp)
    80005bb0:	fc22                	sd	s0,56(sp)
    80005bb2:	e0a6                	sd	s1,64(sp)
    80005bb4:	e4aa                	sd	a0,72(sp)
    80005bb6:	e8ae                	sd	a1,80(sp)
    80005bb8:	ecb2                	sd	a2,88(sp)
    80005bba:	f0b6                	sd	a3,96(sp)
    80005bbc:	f4ba                	sd	a4,104(sp)
    80005bbe:	f8be                	sd	a5,112(sp)
    80005bc0:	fcc2                	sd	a6,120(sp)
    80005bc2:	e146                	sd	a7,128(sp)
    80005bc4:	e54a                	sd	s2,136(sp)
    80005bc6:	e94e                	sd	s3,144(sp)
    80005bc8:	ed52                	sd	s4,152(sp)
    80005bca:	f156                	sd	s5,160(sp)
    80005bcc:	f55a                	sd	s6,168(sp)
    80005bce:	f95e                	sd	s7,176(sp)
    80005bd0:	fd62                	sd	s8,184(sp)
    80005bd2:	e1e6                	sd	s9,192(sp)
    80005bd4:	e5ea                	sd	s10,200(sp)
    80005bd6:	e9ee                	sd	s11,208(sp)
    80005bd8:	edf2                	sd	t3,216(sp)
    80005bda:	f1f6                	sd	t4,224(sp)
    80005bdc:	f5fa                	sd	t5,232(sp)
    80005bde:	f9fe                	sd	t6,240(sp)
    80005be0:	d55fc0ef          	jal	ra,80002934 <kerneltrap>
    80005be4:	6082                	ld	ra,0(sp)
    80005be6:	6122                	ld	sp,8(sp)
    80005be8:	61c2                	ld	gp,16(sp)
    80005bea:	7282                	ld	t0,32(sp)
    80005bec:	7322                	ld	t1,40(sp)
    80005bee:	73c2                	ld	t2,48(sp)
    80005bf0:	7462                	ld	s0,56(sp)
    80005bf2:	6486                	ld	s1,64(sp)
    80005bf4:	6526                	ld	a0,72(sp)
    80005bf6:	65c6                	ld	a1,80(sp)
    80005bf8:	6666                	ld	a2,88(sp)
    80005bfa:	7686                	ld	a3,96(sp)
    80005bfc:	7726                	ld	a4,104(sp)
    80005bfe:	77c6                	ld	a5,112(sp)
    80005c00:	7866                	ld	a6,120(sp)
    80005c02:	688a                	ld	a7,128(sp)
    80005c04:	692a                	ld	s2,136(sp)
    80005c06:	69ca                	ld	s3,144(sp)
    80005c08:	6a6a                	ld	s4,152(sp)
    80005c0a:	7a8a                	ld	s5,160(sp)
    80005c0c:	7b2a                	ld	s6,168(sp)
    80005c0e:	7bca                	ld	s7,176(sp)
    80005c10:	7c6a                	ld	s8,184(sp)
    80005c12:	6c8e                	ld	s9,192(sp)
    80005c14:	6d2e                	ld	s10,200(sp)
    80005c16:	6dce                	ld	s11,208(sp)
    80005c18:	6e6e                	ld	t3,216(sp)
    80005c1a:	7e8e                	ld	t4,224(sp)
    80005c1c:	7f2e                	ld	t5,232(sp)
    80005c1e:	7fce                	ld	t6,240(sp)
    80005c20:	6111                	addi	sp,sp,256
    80005c22:	10200073          	sret
    80005c26:	00000013          	nop
    80005c2a:	00000013          	nop
    80005c2e:	0001                	nop

0000000080005c30 <timervec>:
    80005c30:	34051573          	csrrw	a0,mscratch,a0
    80005c34:	e10c                	sd	a1,0(a0)
    80005c36:	e510                	sd	a2,8(a0)
    80005c38:	e914                	sd	a3,16(a0)
    80005c3a:	6d0c                	ld	a1,24(a0)
    80005c3c:	7110                	ld	a2,32(a0)
    80005c3e:	6194                	ld	a3,0(a1)
    80005c40:	96b2                	add	a3,a3,a2
    80005c42:	e194                	sd	a3,0(a1)
    80005c44:	4589                	li	a1,2
    80005c46:	14459073          	csrw	sip,a1
    80005c4a:	6914                	ld	a3,16(a0)
    80005c4c:	6510                	ld	a2,8(a0)
    80005c4e:	610c                	ld	a1,0(a0)
    80005c50:	34051573          	csrrw	a0,mscratch,a0
    80005c54:	30200073          	mret
	...

0000000080005c5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c5a:	1141                	addi	sp,sp,-16
    80005c5c:	e422                	sd	s0,8(sp)
    80005c5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c60:	0c0007b7          	lui	a5,0xc000
    80005c64:	4705                	li	a4,1
    80005c66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c68:	c3d8                	sw	a4,4(a5)
}
    80005c6a:	6422                	ld	s0,8(sp)
    80005c6c:	0141                	addi	sp,sp,16
    80005c6e:	8082                	ret

0000000080005c70 <plicinithart>:

void
plicinithart(void)
{
    80005c70:	1141                	addi	sp,sp,-16
    80005c72:	e406                	sd	ra,8(sp)
    80005c74:	e022                	sd	s0,0(sp)
    80005c76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c78:	ffffc097          	auipc	ra,0xffffc
    80005c7c:	d82080e7          	jalr	-638(ra) # 800019fa <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c80:	0085171b          	slliw	a4,a0,0x8
    80005c84:	0c0027b7          	lui	a5,0xc002
    80005c88:	97ba                	add	a5,a5,a4
    80005c8a:	40200713          	li	a4,1026
    80005c8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c92:	00d5151b          	slliw	a0,a0,0xd
    80005c96:	0c2017b7          	lui	a5,0xc201
    80005c9a:	953e                	add	a0,a0,a5
    80005c9c:	00052023          	sw	zero,0(a0)
}
    80005ca0:	60a2                	ld	ra,8(sp)
    80005ca2:	6402                	ld	s0,0(sp)
    80005ca4:	0141                	addi	sp,sp,16
    80005ca6:	8082                	ret

0000000080005ca8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ca8:	1141                	addi	sp,sp,-16
    80005caa:	e406                	sd	ra,8(sp)
    80005cac:	e022                	sd	s0,0(sp)
    80005cae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cb0:	ffffc097          	auipc	ra,0xffffc
    80005cb4:	d4a080e7          	jalr	-694(ra) # 800019fa <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cb8:	00d5179b          	slliw	a5,a0,0xd
    80005cbc:	0c201537          	lui	a0,0xc201
    80005cc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005cc2:	4148                	lw	a0,4(a0)
    80005cc4:	60a2                	ld	ra,8(sp)
    80005cc6:	6402                	ld	s0,0(sp)
    80005cc8:	0141                	addi	sp,sp,16
    80005cca:	8082                	ret

0000000080005ccc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ccc:	1101                	addi	sp,sp,-32
    80005cce:	ec06                	sd	ra,24(sp)
    80005cd0:	e822                	sd	s0,16(sp)
    80005cd2:	e426                	sd	s1,8(sp)
    80005cd4:	1000                	addi	s0,sp,32
    80005cd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cd8:	ffffc097          	auipc	ra,0xffffc
    80005cdc:	d22080e7          	jalr	-734(ra) # 800019fa <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ce0:	00d5151b          	slliw	a0,a0,0xd
    80005ce4:	0c2017b7          	lui	a5,0xc201
    80005ce8:	97aa                	add	a5,a5,a0
    80005cea:	c3c4                	sw	s1,4(a5)
}
    80005cec:	60e2                	ld	ra,24(sp)
    80005cee:	6442                	ld	s0,16(sp)
    80005cf0:	64a2                	ld	s1,8(sp)
    80005cf2:	6105                	addi	sp,sp,32
    80005cf4:	8082                	ret

0000000080005cf6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cf6:	1141                	addi	sp,sp,-16
    80005cf8:	e406                	sd	ra,8(sp)
    80005cfa:	e022                	sd	s0,0(sp)
    80005cfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cfe:	479d                	li	a5,7
    80005d00:	06a7c963          	blt	a5,a0,80005d72 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d04:	0001d797          	auipc	a5,0x1d
    80005d08:	2fc78793          	addi	a5,a5,764 # 80023000 <disk>
    80005d0c:	00a78733          	add	a4,a5,a0
    80005d10:	6789                	lui	a5,0x2
    80005d12:	97ba                	add	a5,a5,a4
    80005d14:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d18:	e7ad                	bnez	a5,80005d82 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d1a:	00451793          	slli	a5,a0,0x4
    80005d1e:	0001f717          	auipc	a4,0x1f
    80005d22:	2e270713          	addi	a4,a4,738 # 80025000 <disk+0x2000>
    80005d26:	6314                	ld	a3,0(a4)
    80005d28:	96be                	add	a3,a3,a5
    80005d2a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d2e:	6314                	ld	a3,0(a4)
    80005d30:	96be                	add	a3,a3,a5
    80005d32:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d36:	6314                	ld	a3,0(a4)
    80005d38:	96be                	add	a3,a3,a5
    80005d3a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d3e:	6318                	ld	a4,0(a4)
    80005d40:	97ba                	add	a5,a5,a4
    80005d42:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d46:	0001d797          	auipc	a5,0x1d
    80005d4a:	2ba78793          	addi	a5,a5,698 # 80023000 <disk>
    80005d4e:	97aa                	add	a5,a5,a0
    80005d50:	6509                	lui	a0,0x2
    80005d52:	953e                	add	a0,a0,a5
    80005d54:	4785                	li	a5,1
    80005d56:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d5a:	0001f517          	auipc	a0,0x1f
    80005d5e:	2be50513          	addi	a0,a0,702 # 80025018 <disk+0x2018>
    80005d62:	ffffc097          	auipc	ra,0xffffc
    80005d66:	53c080e7          	jalr	1340(ra) # 8000229e <wakeup>
}
    80005d6a:	60a2                	ld	ra,8(sp)
    80005d6c:	6402                	ld	s0,0(sp)
    80005d6e:	0141                	addi	sp,sp,16
    80005d70:	8082                	ret
    panic("free_desc 1");
    80005d72:	00003517          	auipc	a0,0x3
    80005d76:	a9650513          	addi	a0,a0,-1386 # 80008808 <syscalls+0x340>
    80005d7a:	ffffa097          	auipc	ra,0xffffa
    80005d7e:	7c4080e7          	jalr	1988(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005d82:	00003517          	auipc	a0,0x3
    80005d86:	a9650513          	addi	a0,a0,-1386 # 80008818 <syscalls+0x350>
    80005d8a:	ffffa097          	auipc	ra,0xffffa
    80005d8e:	7b4080e7          	jalr	1972(ra) # 8000053e <panic>

0000000080005d92 <virtio_disk_init>:
{
    80005d92:	1101                	addi	sp,sp,-32
    80005d94:	ec06                	sd	ra,24(sp)
    80005d96:	e822                	sd	s0,16(sp)
    80005d98:	e426                	sd	s1,8(sp)
    80005d9a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d9c:	00003597          	auipc	a1,0x3
    80005da0:	a8c58593          	addi	a1,a1,-1396 # 80008828 <syscalls+0x360>
    80005da4:	0001f517          	auipc	a0,0x1f
    80005da8:	38450513          	addi	a0,a0,900 # 80025128 <disk+0x2128>
    80005dac:	ffffb097          	auipc	ra,0xffffb
    80005db0:	da8080e7          	jalr	-600(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005db4:	100017b7          	lui	a5,0x10001
    80005db8:	4398                	lw	a4,0(a5)
    80005dba:	2701                	sext.w	a4,a4
    80005dbc:	747277b7          	lui	a5,0x74727
    80005dc0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dc4:	0ef71163          	bne	a4,a5,80005ea6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dc8:	100017b7          	lui	a5,0x10001
    80005dcc:	43dc                	lw	a5,4(a5)
    80005dce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dd0:	4705                	li	a4,1
    80005dd2:	0ce79a63          	bne	a5,a4,80005ea6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dd6:	100017b7          	lui	a5,0x10001
    80005dda:	479c                	lw	a5,8(a5)
    80005ddc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dde:	4709                	li	a4,2
    80005de0:	0ce79363          	bne	a5,a4,80005ea6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005de4:	100017b7          	lui	a5,0x10001
    80005de8:	47d8                	lw	a4,12(a5)
    80005dea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dec:	554d47b7          	lui	a5,0x554d4
    80005df0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005df4:	0af71963          	bne	a4,a5,80005ea6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005df8:	100017b7          	lui	a5,0x10001
    80005dfc:	4705                	li	a4,1
    80005dfe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e00:	470d                	li	a4,3
    80005e02:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e04:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e06:	c7ffe737          	lui	a4,0xc7ffe
    80005e0a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e0e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e10:	2701                	sext.w	a4,a4
    80005e12:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e14:	472d                	li	a4,11
    80005e16:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e18:	473d                	li	a4,15
    80005e1a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e1c:	6705                	lui	a4,0x1
    80005e1e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e20:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e24:	5bdc                	lw	a5,52(a5)
    80005e26:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e28:	c7d9                	beqz	a5,80005eb6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e2a:	471d                	li	a4,7
    80005e2c:	08f77d63          	bgeu	a4,a5,80005ec6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e30:	100014b7          	lui	s1,0x10001
    80005e34:	47a1                	li	a5,8
    80005e36:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e38:	6609                	lui	a2,0x2
    80005e3a:	4581                	li	a1,0
    80005e3c:	0001d517          	auipc	a0,0x1d
    80005e40:	1c450513          	addi	a0,a0,452 # 80023000 <disk>
    80005e44:	ffffb097          	auipc	ra,0xffffb
    80005e48:	e9c080e7          	jalr	-356(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e4c:	0001d717          	auipc	a4,0x1d
    80005e50:	1b470713          	addi	a4,a4,436 # 80023000 <disk>
    80005e54:	00c75793          	srli	a5,a4,0xc
    80005e58:	2781                	sext.w	a5,a5
    80005e5a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e5c:	0001f797          	auipc	a5,0x1f
    80005e60:	1a478793          	addi	a5,a5,420 # 80025000 <disk+0x2000>
    80005e64:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e66:	0001d717          	auipc	a4,0x1d
    80005e6a:	21a70713          	addi	a4,a4,538 # 80023080 <disk+0x80>
    80005e6e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e70:	0001e717          	auipc	a4,0x1e
    80005e74:	19070713          	addi	a4,a4,400 # 80024000 <disk+0x1000>
    80005e78:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e7a:	4705                	li	a4,1
    80005e7c:	00e78c23          	sb	a4,24(a5)
    80005e80:	00e78ca3          	sb	a4,25(a5)
    80005e84:	00e78d23          	sb	a4,26(a5)
    80005e88:	00e78da3          	sb	a4,27(a5)
    80005e8c:	00e78e23          	sb	a4,28(a5)
    80005e90:	00e78ea3          	sb	a4,29(a5)
    80005e94:	00e78f23          	sb	a4,30(a5)
    80005e98:	00e78fa3          	sb	a4,31(a5)
}
    80005e9c:	60e2                	ld	ra,24(sp)
    80005e9e:	6442                	ld	s0,16(sp)
    80005ea0:	64a2                	ld	s1,8(sp)
    80005ea2:	6105                	addi	sp,sp,32
    80005ea4:	8082                	ret
    panic("could not find virtio disk");
    80005ea6:	00003517          	auipc	a0,0x3
    80005eaa:	99250513          	addi	a0,a0,-1646 # 80008838 <syscalls+0x370>
    80005eae:	ffffa097          	auipc	ra,0xffffa
    80005eb2:	690080e7          	jalr	1680(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005eb6:	00003517          	auipc	a0,0x3
    80005eba:	9a250513          	addi	a0,a0,-1630 # 80008858 <syscalls+0x390>
    80005ebe:	ffffa097          	auipc	ra,0xffffa
    80005ec2:	680080e7          	jalr	1664(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005ec6:	00003517          	auipc	a0,0x3
    80005eca:	9b250513          	addi	a0,a0,-1614 # 80008878 <syscalls+0x3b0>
    80005ece:	ffffa097          	auipc	ra,0xffffa
    80005ed2:	670080e7          	jalr	1648(ra) # 8000053e <panic>

0000000080005ed6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ed6:	7159                	addi	sp,sp,-112
    80005ed8:	f486                	sd	ra,104(sp)
    80005eda:	f0a2                	sd	s0,96(sp)
    80005edc:	eca6                	sd	s1,88(sp)
    80005ede:	e8ca                	sd	s2,80(sp)
    80005ee0:	e4ce                	sd	s3,72(sp)
    80005ee2:	e0d2                	sd	s4,64(sp)
    80005ee4:	fc56                	sd	s5,56(sp)
    80005ee6:	f85a                	sd	s6,48(sp)
    80005ee8:	f45e                	sd	s7,40(sp)
    80005eea:	f062                	sd	s8,32(sp)
    80005eec:	ec66                	sd	s9,24(sp)
    80005eee:	e86a                	sd	s10,16(sp)
    80005ef0:	1880                	addi	s0,sp,112
    80005ef2:	892a                	mv	s2,a0
    80005ef4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ef6:	00c52c83          	lw	s9,12(a0)
    80005efa:	001c9c9b          	slliw	s9,s9,0x1
    80005efe:	1c82                	slli	s9,s9,0x20
    80005f00:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f04:	0001f517          	auipc	a0,0x1f
    80005f08:	22450513          	addi	a0,a0,548 # 80025128 <disk+0x2128>
    80005f0c:	ffffb097          	auipc	ra,0xffffb
    80005f10:	cd8080e7          	jalr	-808(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005f14:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f16:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f18:	0001db97          	auipc	s7,0x1d
    80005f1c:	0e8b8b93          	addi	s7,s7,232 # 80023000 <disk>
    80005f20:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f22:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f24:	8a4e                	mv	s4,s3
    80005f26:	a051                	j	80005faa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f28:	00fb86b3          	add	a3,s7,a5
    80005f2c:	96da                	add	a3,a3,s6
    80005f2e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f32:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f34:	0207c563          	bltz	a5,80005f5e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f38:	2485                	addiw	s1,s1,1
    80005f3a:	0711                	addi	a4,a4,4
    80005f3c:	25548063          	beq	s1,s5,8000617c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005f40:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f42:	0001f697          	auipc	a3,0x1f
    80005f46:	0d668693          	addi	a3,a3,214 # 80025018 <disk+0x2018>
    80005f4a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f4c:	0006c583          	lbu	a1,0(a3)
    80005f50:	fde1                	bnez	a1,80005f28 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f52:	2785                	addiw	a5,a5,1
    80005f54:	0685                	addi	a3,a3,1
    80005f56:	ff879be3          	bne	a5,s8,80005f4c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f5a:	57fd                	li	a5,-1
    80005f5c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f5e:	02905a63          	blez	s1,80005f92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f62:	f9042503          	lw	a0,-112(s0)
    80005f66:	00000097          	auipc	ra,0x0
    80005f6a:	d90080e7          	jalr	-624(ra) # 80005cf6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f6e:	4785                	li	a5,1
    80005f70:	0297d163          	bge	a5,s1,80005f92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f74:	f9442503          	lw	a0,-108(s0)
    80005f78:	00000097          	auipc	ra,0x0
    80005f7c:	d7e080e7          	jalr	-642(ra) # 80005cf6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f80:	4789                	li	a5,2
    80005f82:	0097d863          	bge	a5,s1,80005f92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f86:	f9842503          	lw	a0,-104(s0)
    80005f8a:	00000097          	auipc	ra,0x0
    80005f8e:	d6c080e7          	jalr	-660(ra) # 80005cf6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f92:	0001f597          	auipc	a1,0x1f
    80005f96:	19658593          	addi	a1,a1,406 # 80025128 <disk+0x2128>
    80005f9a:	0001f517          	auipc	a0,0x1f
    80005f9e:	07e50513          	addi	a0,a0,126 # 80025018 <disk+0x2018>
    80005fa2:	ffffc097          	auipc	ra,0xffffc
    80005fa6:	170080e7          	jalr	368(ra) # 80002112 <sleep>
  for(int i = 0; i < 3; i++){
    80005faa:	f9040713          	addi	a4,s0,-112
    80005fae:	84ce                	mv	s1,s3
    80005fb0:	bf41                	j	80005f40 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005fb2:	20058713          	addi	a4,a1,512
    80005fb6:	00471693          	slli	a3,a4,0x4
    80005fba:	0001d717          	auipc	a4,0x1d
    80005fbe:	04670713          	addi	a4,a4,70 # 80023000 <disk>
    80005fc2:	9736                	add	a4,a4,a3
    80005fc4:	4685                	li	a3,1
    80005fc6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005fca:	20058713          	addi	a4,a1,512
    80005fce:	00471693          	slli	a3,a4,0x4
    80005fd2:	0001d717          	auipc	a4,0x1d
    80005fd6:	02e70713          	addi	a4,a4,46 # 80023000 <disk>
    80005fda:	9736                	add	a4,a4,a3
    80005fdc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005fe0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005fe4:	7679                	lui	a2,0xffffe
    80005fe6:	963e                	add	a2,a2,a5
    80005fe8:	0001f697          	auipc	a3,0x1f
    80005fec:	01868693          	addi	a3,a3,24 # 80025000 <disk+0x2000>
    80005ff0:	6298                	ld	a4,0(a3)
    80005ff2:	9732                	add	a4,a4,a2
    80005ff4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005ff6:	6298                	ld	a4,0(a3)
    80005ff8:	9732                	add	a4,a4,a2
    80005ffa:	4541                	li	a0,16
    80005ffc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005ffe:	6298                	ld	a4,0(a3)
    80006000:	9732                	add	a4,a4,a2
    80006002:	4505                	li	a0,1
    80006004:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006008:	f9442703          	lw	a4,-108(s0)
    8000600c:	6288                	ld	a0,0(a3)
    8000600e:	962a                	add	a2,a2,a0
    80006010:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006014:	0712                	slli	a4,a4,0x4
    80006016:	6290                	ld	a2,0(a3)
    80006018:	963a                	add	a2,a2,a4
    8000601a:	05890513          	addi	a0,s2,88
    8000601e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006020:	6294                	ld	a3,0(a3)
    80006022:	96ba                	add	a3,a3,a4
    80006024:	40000613          	li	a2,1024
    80006028:	c690                	sw	a2,8(a3)
  if(write)
    8000602a:	140d0063          	beqz	s10,8000616a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000602e:	0001f697          	auipc	a3,0x1f
    80006032:	fd26b683          	ld	a3,-46(a3) # 80025000 <disk+0x2000>
    80006036:	96ba                	add	a3,a3,a4
    80006038:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000603c:	0001d817          	auipc	a6,0x1d
    80006040:	fc480813          	addi	a6,a6,-60 # 80023000 <disk>
    80006044:	0001f517          	auipc	a0,0x1f
    80006048:	fbc50513          	addi	a0,a0,-68 # 80025000 <disk+0x2000>
    8000604c:	6114                	ld	a3,0(a0)
    8000604e:	96ba                	add	a3,a3,a4
    80006050:	00c6d603          	lhu	a2,12(a3)
    80006054:	00166613          	ori	a2,a2,1
    80006058:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000605c:	f9842683          	lw	a3,-104(s0)
    80006060:	6110                	ld	a2,0(a0)
    80006062:	9732                	add	a4,a4,a2
    80006064:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006068:	20058613          	addi	a2,a1,512
    8000606c:	0612                	slli	a2,a2,0x4
    8000606e:	9642                	add	a2,a2,a6
    80006070:	577d                	li	a4,-1
    80006072:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006076:	00469713          	slli	a4,a3,0x4
    8000607a:	6114                	ld	a3,0(a0)
    8000607c:	96ba                	add	a3,a3,a4
    8000607e:	03078793          	addi	a5,a5,48
    80006082:	97c2                	add	a5,a5,a6
    80006084:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006086:	611c                	ld	a5,0(a0)
    80006088:	97ba                	add	a5,a5,a4
    8000608a:	4685                	li	a3,1
    8000608c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000608e:	611c                	ld	a5,0(a0)
    80006090:	97ba                	add	a5,a5,a4
    80006092:	4809                	li	a6,2
    80006094:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006098:	611c                	ld	a5,0(a0)
    8000609a:	973e                	add	a4,a4,a5
    8000609c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800060a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060a8:	6518                	ld	a4,8(a0)
    800060aa:	00275783          	lhu	a5,2(a4)
    800060ae:	8b9d                	andi	a5,a5,7
    800060b0:	0786                	slli	a5,a5,0x1
    800060b2:	97ba                	add	a5,a5,a4
    800060b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800060b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060bc:	6518                	ld	a4,8(a0)
    800060be:	00275783          	lhu	a5,2(a4)
    800060c2:	2785                	addiw	a5,a5,1
    800060c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060cc:	100017b7          	lui	a5,0x10001
    800060d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060d4:	00492703          	lw	a4,4(s2)
    800060d8:	4785                	li	a5,1
    800060da:	02f71163          	bne	a4,a5,800060fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800060de:	0001f997          	auipc	s3,0x1f
    800060e2:	04a98993          	addi	s3,s3,74 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800060e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060e8:	85ce                	mv	a1,s3
    800060ea:	854a                	mv	a0,s2
    800060ec:	ffffc097          	auipc	ra,0xffffc
    800060f0:	026080e7          	jalr	38(ra) # 80002112 <sleep>
  while(b->disk == 1) {
    800060f4:	00492783          	lw	a5,4(s2)
    800060f8:	fe9788e3          	beq	a5,s1,800060e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800060fc:	f9042903          	lw	s2,-112(s0)
    80006100:	20090793          	addi	a5,s2,512
    80006104:	00479713          	slli	a4,a5,0x4
    80006108:	0001d797          	auipc	a5,0x1d
    8000610c:	ef878793          	addi	a5,a5,-264 # 80023000 <disk>
    80006110:	97ba                	add	a5,a5,a4
    80006112:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006116:	0001f997          	auipc	s3,0x1f
    8000611a:	eea98993          	addi	s3,s3,-278 # 80025000 <disk+0x2000>
    8000611e:	00491713          	slli	a4,s2,0x4
    80006122:	0009b783          	ld	a5,0(s3)
    80006126:	97ba                	add	a5,a5,a4
    80006128:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000612c:	854a                	mv	a0,s2
    8000612e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006132:	00000097          	auipc	ra,0x0
    80006136:	bc4080e7          	jalr	-1084(ra) # 80005cf6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000613a:	8885                	andi	s1,s1,1
    8000613c:	f0ed                	bnez	s1,8000611e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000613e:	0001f517          	auipc	a0,0x1f
    80006142:	fea50513          	addi	a0,a0,-22 # 80025128 <disk+0x2128>
    80006146:	ffffb097          	auipc	ra,0xffffb
    8000614a:	b52080e7          	jalr	-1198(ra) # 80000c98 <release>
}
    8000614e:	70a6                	ld	ra,104(sp)
    80006150:	7406                	ld	s0,96(sp)
    80006152:	64e6                	ld	s1,88(sp)
    80006154:	6946                	ld	s2,80(sp)
    80006156:	69a6                	ld	s3,72(sp)
    80006158:	6a06                	ld	s4,64(sp)
    8000615a:	7ae2                	ld	s5,56(sp)
    8000615c:	7b42                	ld	s6,48(sp)
    8000615e:	7ba2                	ld	s7,40(sp)
    80006160:	7c02                	ld	s8,32(sp)
    80006162:	6ce2                	ld	s9,24(sp)
    80006164:	6d42                	ld	s10,16(sp)
    80006166:	6165                	addi	sp,sp,112
    80006168:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000616a:	0001f697          	auipc	a3,0x1f
    8000616e:	e966b683          	ld	a3,-362(a3) # 80025000 <disk+0x2000>
    80006172:	96ba                	add	a3,a3,a4
    80006174:	4609                	li	a2,2
    80006176:	00c69623          	sh	a2,12(a3)
    8000617a:	b5c9                	j	8000603c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000617c:	f9042583          	lw	a1,-112(s0)
    80006180:	20058793          	addi	a5,a1,512
    80006184:	0792                	slli	a5,a5,0x4
    80006186:	0001d517          	auipc	a0,0x1d
    8000618a:	f2250513          	addi	a0,a0,-222 # 800230a8 <disk+0xa8>
    8000618e:	953e                	add	a0,a0,a5
  if(write)
    80006190:	e20d11e3          	bnez	s10,80005fb2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006194:	20058713          	addi	a4,a1,512
    80006198:	00471693          	slli	a3,a4,0x4
    8000619c:	0001d717          	auipc	a4,0x1d
    800061a0:	e6470713          	addi	a4,a4,-412 # 80023000 <disk>
    800061a4:	9736                	add	a4,a4,a3
    800061a6:	0a072423          	sw	zero,168(a4)
    800061aa:	b505                	j	80005fca <virtio_disk_rw+0xf4>

00000000800061ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061ac:	1101                	addi	sp,sp,-32
    800061ae:	ec06                	sd	ra,24(sp)
    800061b0:	e822                	sd	s0,16(sp)
    800061b2:	e426                	sd	s1,8(sp)
    800061b4:	e04a                	sd	s2,0(sp)
    800061b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061b8:	0001f517          	auipc	a0,0x1f
    800061bc:	f7050513          	addi	a0,a0,-144 # 80025128 <disk+0x2128>
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	a24080e7          	jalr	-1500(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061c8:	10001737          	lui	a4,0x10001
    800061cc:	533c                	lw	a5,96(a4)
    800061ce:	8b8d                	andi	a5,a5,3
    800061d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061d6:	0001f797          	auipc	a5,0x1f
    800061da:	e2a78793          	addi	a5,a5,-470 # 80025000 <disk+0x2000>
    800061de:	6b94                	ld	a3,16(a5)
    800061e0:	0207d703          	lhu	a4,32(a5)
    800061e4:	0026d783          	lhu	a5,2(a3)
    800061e8:	06f70163          	beq	a4,a5,8000624a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061ec:	0001d917          	auipc	s2,0x1d
    800061f0:	e1490913          	addi	s2,s2,-492 # 80023000 <disk>
    800061f4:	0001f497          	auipc	s1,0x1f
    800061f8:	e0c48493          	addi	s1,s1,-500 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800061fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006200:	6898                	ld	a4,16(s1)
    80006202:	0204d783          	lhu	a5,32(s1)
    80006206:	8b9d                	andi	a5,a5,7
    80006208:	078e                	slli	a5,a5,0x3
    8000620a:	97ba                	add	a5,a5,a4
    8000620c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000620e:	20078713          	addi	a4,a5,512
    80006212:	0712                	slli	a4,a4,0x4
    80006214:	974a                	add	a4,a4,s2
    80006216:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000621a:	e731                	bnez	a4,80006266 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000621c:	20078793          	addi	a5,a5,512
    80006220:	0792                	slli	a5,a5,0x4
    80006222:	97ca                	add	a5,a5,s2
    80006224:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006226:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000622a:	ffffc097          	auipc	ra,0xffffc
    8000622e:	074080e7          	jalr	116(ra) # 8000229e <wakeup>

    disk.used_idx += 1;
    80006232:	0204d783          	lhu	a5,32(s1)
    80006236:	2785                	addiw	a5,a5,1
    80006238:	17c2                	slli	a5,a5,0x30
    8000623a:	93c1                	srli	a5,a5,0x30
    8000623c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006240:	6898                	ld	a4,16(s1)
    80006242:	00275703          	lhu	a4,2(a4)
    80006246:	faf71be3          	bne	a4,a5,800061fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000624a:	0001f517          	auipc	a0,0x1f
    8000624e:	ede50513          	addi	a0,a0,-290 # 80025128 <disk+0x2128>
    80006252:	ffffb097          	auipc	ra,0xffffb
    80006256:	a46080e7          	jalr	-1466(ra) # 80000c98 <release>
}
    8000625a:	60e2                	ld	ra,24(sp)
    8000625c:	6442                	ld	s0,16(sp)
    8000625e:	64a2                	ld	s1,8(sp)
    80006260:	6902                	ld	s2,0(sp)
    80006262:	6105                	addi	sp,sp,32
    80006264:	8082                	ret
      panic("virtio_disk_intr status");
    80006266:	00002517          	auipc	a0,0x2
    8000626a:	63250513          	addi	a0,a0,1586 # 80008898 <syscalls+0x3d0>
    8000626e:	ffffa097          	auipc	ra,0xffffa
    80006272:	2d0080e7          	jalr	720(ra) # 8000053e <panic>
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
