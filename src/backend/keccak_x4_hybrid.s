///
/// Hybrid scalar/NEON four-way Keccak-f[1600] for aarch64 cores whose
/// SHA-3 instructions run on a subset of SIMD units (Neoverse/Cortex
/// before X4, Graviton class).
///   states 0,1: the two-way Armv8.4-A NEON kernel (eor3/rax1/xar/bcax)
///   states 2,3: scalar GPR rounds, lazy rotations -- every rho rides a
///     logical's ror-operand; the stationary per-lane frame assignment
///     was derived by CP-SAT with zero materialized rotates per steady
///     round. Woven 2 scalar rounds : 1 vector round, two passes.
///
///   x0 = state (4 sequential [u64; 25]), x1 = 24 round constants

// The assembler needs the SHA-3 mnemonics enabled regardless of the
// crate's -C target-feature line (LTO release builds assemble
// module-level asm without the target's default features).
.arch armv8.4-a+sha3

.text
.global keccak_f1600_x4_hybrid
.global _keccak_f1600_x4_hybrid
keccak_f1600_x4_hybrid:
_keccak_f1600_x4_hybrid:
        sub sp, sp, #160
        stp x19, x20, [sp, #64]
        stp x21, x22, [sp, #80]
        stp x23, x24, [sp, #96]
        stp x25, x26, [sp, #112]
        stp x27, x28, [sp, #128]
        str x30, [sp, #144]
        stp d8, d9, [sp, #-64]!
        stp d10, d11, [sp, #16]
        stp d12, d13, [sp, #32]
        stp d14, d15, [sp, #48]
        add x2, x0, #200
        ldr q30, [x0, #0]
        ldr q31, [x2, #0]
        trn1 v0.2d, v30.2d, v31.2d
        trn2 v1.2d, v30.2d, v31.2d
        ldr q30, [x0, #16]
        ldr q31, [x2, #16]
        trn1 v2.2d, v30.2d, v31.2d
        trn2 v3.2d, v30.2d, v31.2d
        ldr q30, [x0, #32]
        ldr q31, [x2, #32]
        trn1 v4.2d, v30.2d, v31.2d
        trn2 v5.2d, v30.2d, v31.2d
        ldr q30, [x0, #48]
        ldr q31, [x2, #48]
        trn1 v6.2d, v30.2d, v31.2d
        trn2 v7.2d, v30.2d, v31.2d
        ldr q30, [x0, #64]
        ldr q31, [x2, #64]
        trn1 v8.2d, v30.2d, v31.2d
        trn2 v9.2d, v30.2d, v31.2d
        ldr q30, [x0, #80]
        ldr q31, [x2, #80]
        trn1 v10.2d, v30.2d, v31.2d
        trn2 v11.2d, v30.2d, v31.2d
        ldr q30, [x0, #96]
        ldr q31, [x2, #96]
        trn1 v12.2d, v30.2d, v31.2d
        trn2 v13.2d, v30.2d, v31.2d
        ldr q30, [x0, #112]
        ldr q31, [x2, #112]
        trn1 v14.2d, v30.2d, v31.2d
        trn2 v15.2d, v30.2d, v31.2d
        ldr q30, [x0, #128]
        ldr q31, [x2, #128]
        trn1 v16.2d, v30.2d, v31.2d
        trn2 v17.2d, v30.2d, v31.2d
        ldr q30, [x0, #144]
        ldr q31, [x2, #144]
        trn1 v18.2d, v30.2d, v31.2d
        trn2 v19.2d, v30.2d, v31.2d
        ldr q30, [x0, #160]
        ldr q31, [x2, #160]
        trn1 v20.2d, v30.2d, v31.2d
        trn2 v21.2d, v30.2d, v31.2d
        ldr q30, [x0, #176]
        ldr q31, [x2, #176]
        trn1 v22.2d, v30.2d, v31.2d
        trn2 v23.2d, v30.2d, v31.2d
        ldr d24, [x0, #192]
        ldr d30, [x0, #392]
        mov v24.d[1], v30.d[0]
        ldr x30, [x0, #400]
        ldr x28, [x0, #408]
        ldr x27, [x0, #416]
        ldr x26, [x0, #424]
        ldr x25, [x0, #432]
        ldr x24, [x0, #440]
        ldr x23, [x0, #448]
        ldr x22, [x0, #456]
        ldr x21, [x0, #464]
        ldr x20, [x0, #472]
        ldr x19, [x0, #480]
        ldr x17, [x0, #488]
        ldr x16, [x0, #496]
        ldr x15, [x0, #504]
        ldr x14, [x0, #512]
        ldr x13, [x0, #520]
        ldr x12, [x0, #528]
        ldr x11, [x0, #536]
        ldr x10, [x0, #544]
        ldr x9, [x0, #552]
        ldr x8, [x0, #560]
        ldr x7, [x0, #568]
        ldr x6, [x0, #576]
        ldr x5, [x0, #584]
        ldr x4, [x0, #592]
        eor x3, x30, x24
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x3, x3, x19
        eor x3, x3, x13
        eor x3, x3, x8
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x28, x23
        eor x2, x2, x17
        eor x2, x2, x12
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x7
        str x30, [sp, #80]
        eor x30, x27, x22
        eor x30, x30, x16
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x30, x30, x11
        eor x30, x30, x6
        str x24, [sp, #88]
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        eor x24, x26, x21
        eor x24, x24, x15
        eor x24, x24, x10
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x24, x24, x5
        str x19, [sp, #96]
        eor x19, x25, x20
        eor x19, x19, x14
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x19, x19, x9
        eor x19, x19, x4
        str x13, [sp, #104]
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x13, x3, x30, ror #63
        eor x28, x13, x28
        eor x23, x13, x23
        eor x17, x13, x17
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x12, x13, x12
        eor x7, x13, x7
        eor x13, x2, x24, ror #63
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x27, x13, x27
        eor x22, x13, x22
        eor x16, x13, x16
        rax1 v30.2d, v29.2d, v26.2d
        eor x11, x13, x11
        eor x6, x13, x6
        eor x13, x19, x2, ror #63
        eor x2, x30, x19, ror #63
        rax1 v31.2d, v26.2d, v28.2d
        eor x26, x2, x26
        eor x21, x2, x21
        eor x15, x2, x15
        rax1 v26.2d, v25.2d, v27.2d
        eor x10, x2, x10
        eor x5, x2, x5
        eor x30, x24, x3, ror #63
        rax1 v27.2d, v27.2d, v29.2d
        eor x25, x30, x25
        eor x20, x30, x20
        eor x14, x30, x14
        eor x9, x30, x9
        rax1 v28.2d, v28.2d, v25.2d
        eor x4, x30, x4
        ldr x19, [sp, #80]
        eor x19, x13, x19
        eor v0.16b, v0.16b, v30.16b
        ldr x30, [sp, #88]
        eor x30, x13, x30
        ldr x24, [sp, #96]
        eor x24, x13, x24
        mov v25.16b, v1.16b
        ldr x3, [sp, #104]
        eor x3, x13, x3
        eor x8, x13, x8
        xar v1.2d, v6.2d, v26.2d, #20
        mov x13, x19
        mov x2, x23
        str x28, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        bic x28, x16, x23, ror #63
        eor x19, x19, x28, ror #21
        bic x28, x10, x16, ror #42
        eor x23, x23, x28, ror #23
        xar v9.2d, v22.2d, v31.2d, #3
        ror x23, x23, #19
        bic x28, x4, x10, ror #57
        eor x16, x16, x28, ror #29
        xar v22.2d, v14.2d, v28.2d, #25
        ror x16, x16, #39
        bic x28, x13, x4, ror #50
        eor x10, x28, x10, ror #43
        xar v14.2d, v20.2d, v30.2d, #46
        bic x28, x2, x13, ror #44
        eor x4, x4, x28, ror #34
        ror x4, x4, #9
        mov x2, x26
        xar v20.2d, v2.2d, v31.2d, #2
        mov x13, x20
        bic x28, x24, x20, ror #47
        eor x26, x28, x26, ror #39
        xar v2.2d, v12.2d, v31.2d, #21
        bic x28, x12, x24, ror #42
        eor x20, x20, x28, ror #39
        ror x20, x20, #4
        bic x28, x6, x12, ror #16
        xar v12.2d, v13.2d, v27.2d, #39
        eor x24, x24, x28, ror #6
        ror x24, x24, #39
        bic x28, x2, x6, ror #31
        xar v13.2d, v19.2d, v28.2d, #56
        eor x12, x12, x28, ror #17
        ror x12, x12, #25
        bic x28, x13, x2, ror #56
        xar v19.2d, v23.2d, v27.2d, #8
        eor x6, x6, x28, ror #41
        ror x6, x6, #27
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x28, x22
        str x19, [sp, #104]
        bic x19, x15, x22, ror #19
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x13, x19, ror #40
        ror x13, x13, #2
        bic x19, x9, x15, ror #47
        eor x22, x22, x19, ror #62
        xar v4.2d, v24.2d, v28.2d, #50
        ror x22, x22, #6
        bic x19, x8, x9, ror #10
        eor x15, x19, x15, ror #57
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x2, x8, ror #47
        eor x9, x9, x19, ror #7
        ror x9, x9, #36
        xar v21.2d, v8.2d, v27.2d, #9
        bic x19, x28, x2, ror #5
        eor x8, x8, x19, ror #12
        ror x8, x8, #33
        mov x28, x25
        xar v8.2d, v16.2d, v26.2d, #19
        mov x2, x30
        bic x19, x17, x30, ror #38
        eor x25, x25, x19, ror #17
        xar v16.2d, v5.2d, v30.2d, #28
        ror x25, x25, #26
        bic x19, x11, x17, ror #5
        eor x30, x30, x19, ror #21
        xar v5.2d, v3.2d, v27.2d, #36
        ror x30, x30, #24
        bic x19, x5, x11, ror #41
        eor x17, x17, x19, ror #18
        ror x17, x17, #24
        xar v3.2d, v18.2d, v27.2d, #43
        bic x19, x28, x5, ror #35
        eor x11, x11, x19, ror #52
        ror x11, x11, #16
        xar v18.2d, v17.2d, v31.2d, #49
        bic x19, x2, x28, ror #9
        eor x5, x19, x5, ror #44
        mov x2, x27
        mov x28, x21
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x14, x21, ror #48
        eor x27, x27, x19, ror #23
        ror x27, x27, #45
        xar v11.2d, v7.2d, v31.2d, #58
        bic x19, x3, x14, ror #2
        eor x21, x19, x21, ror #50
        bic x19, x7, x3, ror #25
        xar v7.2d, v10.2d, v30.2d, #61
        eor x14, x14, x19, ror #37
        ror x14, x14, #6
        bic x19, x2, x7, ror #60
        eor x3, x3, x19, ror #43
        xar v10.2d, v25.2d, v26.2d, #63
        ror x3, x3, #2
        bic x19, x28, x2, ror #57
        eor x7, x7, x19, ror #11
        mov v29.16b, v0.16b
        ror x7, x7, #31
        ldr x28, [x1], #8
        ldr x2, [sp, #104]
        mov v30.16b, v1.16b
        eor x2, x2, x28
        eor x28, x26, x2, ror #3
        eor x28, x28, x13
        eor x28, x28, x25, ror #14
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x28, x28, x27, ror #24
        eor x19, x23, x20, ror #39
        eor x19, x19, x22, ror #51
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x19, x19, x30, ror #3
        eor x19, x19, x21, ror #22
        str x27, [sp, #104]
        eor x27, x24, x16, ror #24
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        eor x27, x27, x15, ror #24
        eor x27, x27, x17, ror #8
        eor x27, x27, x14, ror #61
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        str x26, [sp, #96]
        eor x26, x9, x10, ror #44
        eor x26, x26, x12, ror #38
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x26, x26, x11, ror #13
        eor x26, x26, x3, ror #1
        str x25, [sp, #88]
        eor x25, x7, x4, ror #10
        mov v29.16b, v5.16b
        eor x25, x25, x6, ror #9
        eor x25, x25, x8, ror #46
        eor x25, x25, x5, ror #61
        mov v30.16b, v6.16b
        str x13, [sp, #80]
        eor x13, x27, x28, ror #40
        eor x23, x13, x23, ror #44
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x20, x13, x20, ror #19
        eor x22, x13, x22, ror #31
        eor x30, x13, x30, ror #47
        eor x21, x13, x21, ror #2
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x13, x26, x19, ror #46
        eor x16, x13, x16, ror #27
        eor x24, x13, x24, ror #3
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x15, x13, x15, ror #27
        eor x17, x13, x17, ror #11
        eor x14, x13, x14
        eor x13, x19, x25, ror #31
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x19, x27, x25, ror #8
        eor x10, x19, x10, ror #42
        eor x12, x19, x12, ror #36
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x9, x19, x9, ror #62
        eor x11, x19, x11, ror #11
        eor x3, x19, x3, ror #63
        mov v29.16b, v10.16b
        eor x27, x28, x26, ror #24
        eor x4, x27, x4, ror #45
        eor x6, x27, x6, ror #44
        eor x8, x27, x8, ror #17
        mov v30.16b, v11.16b
        eor x5, x27, x5, ror #32
        eor x7, x27, x7, ror #35
        eor x2, x13, x2
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        ldr x25, [sp, #96]
        eor x25, x13, x25, ror #61
        ldr x27, [sp, #80]
        eor x27, x13, x27, ror #61
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        ldr x26, [sp, #88]
        eor x26, x13, x26, ror #11
        ldr x28, [sp, #104]
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x28, x13, x28, ror #21
        mov x13, x2
        mov x19, x20
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        str x23, [sp, #104]
        bic x23, x15, x20, ror #1
        eor x2, x2, x23, ror #40
        bic x23, x11, x15, ror #39
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x20, x23, x20, ror #40
        bic x23, x7, x11, ror #19
        eor x15, x23, x15, ror #58
        mov v29.16b, v15.16b
        bic x23, x13, x7, ror #46
        eor x11, x23, x11, ror #1
        bic x23, x19, x13, ror #23
        mov v30.16b, v16.16b
        eor x7, x23, x7, ror #5
        mov x19, x10
        mov x13, x6
        bic x23, x27, x6, ror #43
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        eor x10, x23, x10, ror #61
        bic x23, x30, x27, ror #21
        eor x6, x6, x23
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x23, x14, x30, ror #18
        eor x27, x23, x27, ror #39
        bic x23, x19, x14, ror #28
        eor x30, x23, x30, ror #46
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        bic x23, x13, x19, ror #18
        eor x14, x23, x14, ror #46
        ldr x13, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        mov x19, x13
        mov x23, x24
        str x2, [sp, #104]
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        bic x2, x9, x24, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x5, x9, ror #9
        eor x24, x2, x24, ror #25
        mov v29.16b, v20.16b
        bic x2, x28, x5, ror #6
        eor x9, x2, x9, ror #15
        bic x2, x19, x28, ror #26
        mov v30.16b, v21.16b
        eor x5, x2, x5, ror #32
        bic x2, x23, x19, ror #7
        eor x28, x2, x28, ror #33
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        mov x23, x4
        mov x19, x25
        bic x2, x22, x25, ror #17
        eor x4, x2, x4, ror #22
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x17, x22, ror #7
        eor x25, x2, x25, ror #24
        bic x2, x3, x17, ror #38
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x22, x2, x22, ror #45
        bic x2, x23, x3, ror #61
        eor x17, x2, x17, ror #35
        bic x2, x19, x23, ror #5
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        eor x3, x2, x3, ror #2
        mov x19, x16
        mov x23, x12
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        bic x2, x8, x12, ror #10
        eor x16, x16, x2
        bic x2, x26, x8, ror #62
        ldr d31, [x1, #-8]
        eor x12, x2, x12, ror #8
        bic x2, x21, x26, ror #4
        eor x8, x2, x8, ror #2
        bic x2, x19, x21, ror #62
        dup v31.2d, v31.d[0]
        eor x26, x2, x26, ror #2
        bic x2, x23, x19, ror #54
        eor x21, x2, x21, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x23, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x23
        eor x23, x10, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x23, x23, x13
        eor x23, x23, x4, ror #14
        eor x23, x23, x16, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x20, x6, ror #39
        eor x2, x2, x24, ror #51
        eor x2, x2, x25, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x12, ror #22
        str x16, [sp, #104]
        eor x16, x27, x15, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x16, x16, x9, ror #24
        eor x16, x16, x22, ror #8
        eor x16, x16, x8, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x10, [sp, #88]
        eor x10, x5, x11, ror #44
        eor x10, x10, x30, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x10, x10, x17, ror #13
        eor x10, x10, x26, ror #1
        str x4, [sp, #80]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x4, x21, x7, ror #10
        eor x4, x4, x14, ror #9
        eor x4, x4, x28, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x4, x4, x3, ror #61
        str x13, [sp, #96]
        eor x13, x16, x23, ror #40
        eor x20, x13, x20, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x6, x13, x6, ror #19
        eor x24, x13, x24, ror #31
        eor x25, x13, x25, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x12, x13, x12, ror #2
        eor x13, x10, x2, ror #46
        eor x15, x13, x15, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x27, x13, x27, ror #3
        eor x9, x13, x9, ror #27
        eor x22, x13, x22, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x8, x13, x8
        eor x13, x2, x4, ror #31
        eor x2, x16, x4, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x11, x2, x11, ror #42
        eor x30, x2, x30, ror #36
        eor x5, x2, x5, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x17, x2, x17, ror #11
        eor x26, x2, x26, ror #63
        eor x16, x23, x10, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x7, x16, x7, ror #45
        eor x14, x16, x14, ror #44
        eor x28, x16, x28, ror #17
        eor x3, x16, x3, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x21, x16, x21, ror #35
        eor x19, x13, x19
        ldr x4, [sp, #88]
        mov v25.16b, v1.16b
        eor x4, x13, x4, ror #61
        ldr x16, [sp, #96]
        eor x16, x13, x16, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x10, [sp, #80]
        eor x10, x13, x10, ror #11
        ldr x23, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x23, x13, x23, ror #21
        mov x13, x19
        mov x2, x6
        xar v9.2d, v22.2d, v31.2d, #3
        str x20, [sp, #104]
        bic x20, x9, x6, ror #1
        eor x19, x19, x20, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x20, x17, x9, ror #39
        eor x6, x20, x6, ror #40
        bic x20, x21, x17, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x9, x20, x9, ror #58
        bic x20, x13, x21, ror #46
        eor x17, x20, x17, ror #1
        bic x20, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x21, x20, x21, ror #5
        mov x2, x11
        mov x13, x14
        xar v2.2d, v12.2d, v31.2d, #21
        bic x20, x16, x14, ror #43
        eor x11, x20, x11, ror #61
        bic x20, x25, x16, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x14, x14, x20
        bic x20, x8, x25, ror #18
        eor x16, x20, x16, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x20, x2, x8, ror #28
        eor x25, x20, x25, ror #46
        bic x20, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x8, x20, x8, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x20, x27
        str x19, [sp, #104]
        bic x19, x5, x27, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x3, x5, ror #9
        eor x27, x19, x27, ror #25
        bic x19, x23, x3, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x5, x19, x5, ror #15
        bic x19, x2, x23, ror #26
        eor x3, x19, x3, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x20, x2, ror #7
        eor x23, x19, x23, ror #33
        mov x20, x7
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x4
        bic x19, x24, x4, ror #17
        eor x7, x19, x7, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x22, x24, ror #7
        eor x4, x19, x4, ror #24
        bic x19, x26, x22, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x24, x19, x24, ror #45
        bic x19, x20, x26, ror #61
        eor x22, x19, x22, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x20, ror #5
        eor x26, x19, x26, ror #2
        mov x2, x15
        xar v3.2d, v18.2d, v27.2d, #43
        mov x20, x30
        bic x19, x28, x30, ror #10
        eor x15, x15, x19
        bic x19, x10, x28, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x30, x19, x30, ror #8
        bic x19, x12, x10, ror #4
        eor x28, x19, x28, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x12, ror #62
        eor x10, x19, x10, ror #2
        bic x19, x20, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x12, x19, x12, ror #52
        ldr x20, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x20
        eor x20, x11, x2, ror #3
        eor x20, x20, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x20, x20, x7, ror #14
        eor x20, x20, x15, ror #24
        eor x19, x6, x14, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x27, ror #51
        eor x19, x19, x4, ror #3
        eor x19, x19, x30, ror #22
        mov v30.16b, v1.16b
        str x15, [sp, #104]
        eor x15, x16, x9, ror #24
        eor x15, x15, x5, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x15, x15, x24, ror #8
        eor x15, x15, x28, ror #61
        str x11, [sp, #80]
        eor x11, x3, x17, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x11, x11, x25, ror #38
        eor x11, x11, x22, ror #13
        eor x11, x11, x10, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x7, [sp, #96]
        eor x7, x12, x21, ror #10
        eor x7, x7, x8, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x7, x7, x23, ror #46
        eor x7, x7, x26, ror #61
        str x13, [sp, #88]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x15, x20, ror #40
        eor x6, x13, x6, ror #44
        eor x14, x13, x14, ror #19
        mov v29.16b, v5.16b
        eor x27, x13, x27, ror #31
        eor x4, x13, x4, ror #47
        eor x30, x13, x30, ror #2
        mov v30.16b, v6.16b
        eor x13, x11, x19, ror #46
        eor x9, x13, x9, ror #27
        eor x16, x13, x16, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x5, x13, x5, ror #27
        eor x24, x13, x24, ror #11
        eor x28, x13, x28
        eor x13, x19, x7, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x15, x7, ror #8
        eor x17, x19, x17, ror #42
        eor x25, x19, x25, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x3, x19, x3, ror #62
        eor x22, x19, x22, ror #11
        eor x10, x19, x10, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x15, x20, x11, ror #24
        eor x21, x15, x21, ror #45
        eor x8, x15, x8, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x23, x15, x23, ror #17
        eor x26, x15, x26, ror #32
        eor x12, x15, x12, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x7, [sp, #80]
        eor x7, x13, x7, ror #61
        mov v30.16b, v11.16b
        ldr x15, [sp, #88]
        eor x15, x13, x15, ror #61
        ldr x11, [sp, #96]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x11, x13, x11, ror #11
        ldr x20, [sp, #104]
        eor x20, x13, x20, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x14
        str x6, [sp, #104]
        bic x6, x5, x14, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x6, ror #40
        bic x6, x22, x5, ror #39
        eor x14, x6, x14, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x6, x12, x22, ror #19
        eor x5, x6, x5, ror #58
        bic x6, x13, x12, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x22, x6, x22, ror #1
        bic x6, x19, x13, ror #23
        eor x12, x6, x12, ror #5
        mov v29.16b, v15.16b
        mov x19, x17
        mov x13, x8
        bic x6, x15, x8, ror #43
        mov v30.16b, v16.16b
        eor x17, x6, x17, ror #61
        bic x6, x4, x15, ror #21
        eor x8, x8, x6
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x6, x28, x4, ror #18
        eor x15, x6, x15, ror #39
        bic x6, x19, x28, ror #28
        eor x4, x6, x4, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x6, x13, x19, ror #18
        eor x28, x6, x28, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x6, x16
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x3, x16, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x26, x3, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x16, x2, x16, ror #25
        bic x2, x20, x26, ror #6
        eor x3, x2, x3, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x20, ror #26
        eor x26, x2, x26, ror #32
        bic x2, x6, x19, ror #7
        mov v30.16b, v21.16b
        eor x20, x2, x20, ror #33
        mov x6, x21
        mov x19, x7
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x27, x7, ror #17
        eor x21, x2, x21, ror #22
        bic x2, x24, x27, ror #7
        eor x7, x2, x7, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x10, x24, ror #38
        eor x27, x2, x27, ror #45
        bic x2, x6, x10, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x24, x2, x24, ror #35
        bic x2, x19, x6, ror #5
        eor x10, x2, x10, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x9
        mov x6, x25
        bic x2, x23, x25, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x9, x9, x2
        bic x2, x11, x23, ror #62
        eor x25, x2, x25, ror #8
        ldr d31, [x1, #-16]
        bic x2, x30, x11, ror #4
        eor x23, x2, x23, ror #2
        bic x2, x19, x30, ror #62
        dup v31.2d, v31.d[0]
        eor x11, x2, x11, ror #2
        bic x2, x6, x19, ror #54
        eor x30, x2, x30, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x6, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x6
        eor x6, x17, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x6, x6, x13
        eor x6, x6, x21, ror #14
        eor x6, x6, x9, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x14, x8, ror #39
        eor x2, x2, x16, ror #51
        eor x2, x2, x7, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x25, ror #22
        str x9, [sp, #104]
        eor x9, x15, x5, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x9, x9, x3, ror #24
        eor x9, x9, x27, ror #8
        eor x9, x9, x23, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x17, [sp, #96]
        eor x17, x26, x22, ror #44
        eor x17, x17, x4, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x17, x17, x24, ror #13
        eor x17, x17, x11, ror #1
        str x21, [sp, #88]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x21, x30, x12, ror #10
        eor x21, x21, x28, ror #9
        eor x21, x21, x20, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x21, x21, x10, ror #61
        str x13, [sp, #80]
        eor x13, x9, x6, ror #40
        eor x14, x13, x14, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x8, x13, x8, ror #19
        eor x16, x13, x16, ror #31
        eor x7, x13, x7, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x25, x13, x25, ror #2
        eor x13, x17, x2, ror #46
        eor x5, x13, x5, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x15, x13, x15, ror #3
        eor x3, x13, x3, ror #27
        eor x27, x13, x27, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x23, x13, x23
        eor x13, x2, x21, ror #31
        eor x2, x9, x21, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x22, x2, x22, ror #42
        eor x4, x2, x4, ror #36
        eor x26, x2, x26, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x24, x2, x24, ror #11
        eor x11, x2, x11, ror #63
        eor x9, x6, x17, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x12, x9, x12, ror #45
        eor x28, x9, x28, ror #44
        eor x20, x9, x20, ror #17
        eor x10, x9, x10, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x30, x9, x30, ror #35
        eor x19, x13, x19
        ldr x21, [sp, #96]
        mov v25.16b, v1.16b
        eor x21, x13, x21, ror #61
        ldr x9, [sp, #80]
        eor x9, x13, x9, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x17, [sp, #88]
        eor x17, x13, x17, ror #11
        ldr x6, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x6, x13, x6, ror #21
        mov x13, x19
        mov x2, x8
        xar v9.2d, v22.2d, v31.2d, #3
        str x14, [sp, #104]
        bic x14, x3, x8, ror #1
        eor x19, x19, x14, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x14, x24, x3, ror #39
        eor x8, x14, x8, ror #40
        bic x14, x30, x24, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x3, x14, x3, ror #58
        bic x14, x13, x30, ror #46
        eor x24, x14, x24, ror #1
        bic x14, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x30, x14, x30, ror #5
        mov x2, x22
        mov x13, x28
        xar v2.2d, v12.2d, v31.2d, #21
        bic x14, x9, x28, ror #43
        eor x22, x14, x22, ror #61
        bic x14, x7, x9, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x28, x28, x14
        bic x14, x23, x7, ror #18
        eor x9, x14, x9, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x14, x2, x23, ror #28
        eor x7, x14, x7, ror #46
        bic x14, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x23, x14, x23, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x14, x15
        str x19, [sp, #104]
        bic x19, x26, x15, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x10, x26, ror #9
        eor x15, x19, x15, ror #25
        bic x19, x6, x10, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x26, x19, x26, ror #15
        bic x19, x2, x6, ror #26
        eor x10, x19, x10, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x14, x2, ror #7
        eor x6, x19, x6, ror #33
        mov x14, x12
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x21
        bic x19, x16, x21, ror #17
        eor x12, x19, x12, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x27, x16, ror #7
        eor x21, x19, x21, ror #24
        bic x19, x11, x27, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x16, x19, x16, ror #45
        bic x19, x14, x11, ror #61
        eor x27, x19, x27, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x14, ror #5
        eor x11, x19, x11, ror #2
        mov x2, x5
        xar v3.2d, v18.2d, v27.2d, #43
        mov x14, x4
        bic x19, x20, x4, ror #10
        eor x5, x5, x19
        bic x19, x17, x20, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x4, x19, x4, ror #8
        bic x19, x25, x17, ror #4
        eor x20, x19, x20, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x25, ror #62
        eor x17, x19, x17, ror #2
        bic x19, x14, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x25, x19, x25, ror #52
        ldr x14, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x14
        eor x14, x22, x2, ror #3
        eor x14, x14, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x14, x14, x12, ror #14
        eor x14, x14, x5, ror #24
        eor x19, x8, x28, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x15, ror #51
        eor x19, x19, x21, ror #3
        eor x19, x19, x4, ror #22
        mov v30.16b, v1.16b
        str x5, [sp, #104]
        eor x5, x9, x3, ror #24
        eor x5, x5, x26, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x5, x5, x16, ror #8
        eor x5, x5, x20, ror #61
        str x22, [sp, #88]
        eor x22, x10, x24, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x22, x22, x7, ror #38
        eor x22, x22, x27, ror #13
        eor x22, x22, x17, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x12, [sp, #80]
        eor x12, x25, x30, ror #10
        eor x12, x12, x23, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x12, x12, x6, ror #46
        eor x12, x12, x11, ror #61
        str x13, [sp, #96]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x5, x14, ror #40
        eor x8, x13, x8, ror #44
        eor x28, x13, x28, ror #19
        mov v29.16b, v5.16b
        eor x15, x13, x15, ror #31
        eor x21, x13, x21, ror #47
        eor x4, x13, x4, ror #2
        mov v30.16b, v6.16b
        eor x13, x22, x19, ror #46
        eor x3, x13, x3, ror #27
        eor x9, x13, x9, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x26, x13, x26, ror #27
        eor x16, x13, x16, ror #11
        eor x20, x13, x20
        eor x13, x19, x12, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x5, x12, ror #8
        eor x24, x19, x24, ror #42
        eor x7, x19, x7, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x10, x19, x10, ror #62
        eor x27, x19, x27, ror #11
        eor x17, x19, x17, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x5, x14, x22, ror #24
        eor x30, x5, x30, ror #45
        eor x23, x5, x23, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x6, x5, x6, ror #17
        eor x11, x5, x11, ror #32
        eor x25, x5, x25, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x12, [sp, #88]
        eor x12, x13, x12, ror #61
        mov v30.16b, v11.16b
        ldr x5, [sp, #96]
        eor x5, x13, x5, ror #61
        ldr x22, [sp, #80]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x22, x13, x22, ror #11
        ldr x14, [sp, #104]
        eor x14, x13, x14, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x28
        str x8, [sp, #104]
        bic x8, x26, x28, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x8, ror #40
        bic x8, x27, x26, ror #39
        eor x28, x8, x28, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x8, x25, x27, ror #19
        eor x26, x8, x26, ror #58
        bic x8, x13, x25, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x27, x8, x27, ror #1
        bic x8, x19, x13, ror #23
        eor x25, x8, x25, ror #5
        mov v29.16b, v15.16b
        mov x19, x24
        mov x13, x23
        bic x8, x5, x23, ror #43
        mov v30.16b, v16.16b
        eor x24, x8, x24, ror #61
        bic x8, x21, x5, ror #21
        eor x23, x23, x8
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x8, x20, x21, ror #18
        eor x5, x8, x5, ror #39
        bic x8, x19, x20, ror #28
        eor x21, x8, x21, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x8, x13, x19, ror #18
        eor x20, x8, x20, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x8, x9
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x10, x9, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x11, x10, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x9, x2, x9, ror #25
        bic x2, x14, x11, ror #6
        eor x10, x2, x10, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x14, ror #26
        eor x11, x2, x11, ror #32
        bic x2, x8, x19, ror #7
        mov v30.16b, v21.16b
        eor x14, x2, x14, ror #33
        mov x8, x30
        mov x19, x12
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x15, x12, ror #17
        eor x30, x2, x30, ror #22
        bic x2, x16, x15, ror #7
        eor x12, x2, x12, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x17, x16, ror #38
        eor x15, x2, x15, ror #45
        bic x2, x8, x17, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x16, x2, x16, ror #35
        bic x2, x19, x8, ror #5
        eor x17, x2, x17, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x3
        mov x8, x7
        bic x2, x6, x7, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x3, x3, x2
        bic x2, x22, x6, ror #62
        eor x7, x2, x7, ror #8
        ldr d31, [x1, #-24]
        bic x2, x4, x22, ror #4
        eor x6, x2, x6, ror #2
        bic x2, x19, x4, ror #62
        dup v31.2d, v31.d[0]
        eor x22, x2, x22, ror #2
        bic x2, x8, x19, ror #54
        eor x4, x2, x4, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x8, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x8
        eor x8, x24, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x8, x8, x13
        eor x8, x8, x30, ror #14
        eor x8, x8, x3, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x28, x23, ror #39
        eor x2, x2, x9, ror #51
        eor x2, x2, x12, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x7, ror #22
        str x3, [sp, #104]
        eor x3, x5, x26, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x3, x3, x10, ror #24
        eor x3, x3, x15, ror #8
        eor x3, x3, x6, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x24, [sp, #80]
        eor x24, x11, x27, ror #44
        eor x24, x24, x21, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x24, x24, x16, ror #13
        eor x24, x24, x22, ror #1
        str x30, [sp, #96]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x30, x4, x25, ror #10
        eor x30, x30, x20, ror #9
        eor x30, x30, x14, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x30, x30, x17, ror #61
        str x13, [sp, #88]
        eor x13, x3, x8, ror #40
        eor x28, x13, x28, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x23, x13, x23, ror #19
        eor x9, x13, x9, ror #31
        eor x12, x13, x12, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x7, x13, x7, ror #2
        eor x13, x24, x2, ror #46
        eor x26, x13, x26, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x5, x13, x5, ror #3
        eor x10, x13, x10, ror #27
        eor x15, x13, x15, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x6, x13, x6
        eor x13, x2, x30, ror #31
        eor x2, x3, x30, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x27, x2, x27, ror #42
        eor x21, x2, x21, ror #36
        eor x11, x2, x11, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x16, x2, x16, ror #11
        eor x22, x2, x22, ror #63
        eor x3, x8, x24, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x25, x3, x25, ror #45
        eor x20, x3, x20, ror #44
        eor x14, x3, x14, ror #17
        eor x17, x3, x17, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x4, x3, x4, ror #35
        eor x19, x13, x19
        ldr x30, [sp, #80]
        mov v25.16b, v1.16b
        eor x30, x13, x30, ror #61
        ldr x3, [sp, #88]
        eor x3, x13, x3, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x24, [sp, #96]
        eor x24, x13, x24, ror #11
        ldr x8, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x8, x13, x8, ror #21
        mov x13, x19
        mov x2, x23
        xar v9.2d, v22.2d, v31.2d, #3
        str x28, [sp, #104]
        bic x28, x10, x23, ror #1
        eor x19, x19, x28, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x28, x16, x10, ror #39
        eor x23, x28, x23, ror #40
        bic x28, x4, x16, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x10, x28, x10, ror #58
        bic x28, x13, x4, ror #46
        eor x16, x28, x16, ror #1
        bic x28, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x4, x28, x4, ror #5
        mov x2, x27
        mov x13, x20
        xar v2.2d, v12.2d, v31.2d, #21
        bic x28, x3, x20, ror #43
        eor x27, x28, x27, ror #61
        bic x28, x12, x3, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x20, x20, x28
        bic x28, x6, x12, ror #18
        eor x3, x28, x3, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x28, x2, x6, ror #28
        eor x12, x28, x12, ror #46
        bic x28, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x6, x28, x6, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x28, x5
        str x19, [sp, #104]
        bic x19, x11, x5, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x17, x11, ror #9
        eor x5, x19, x5, ror #25
        bic x19, x8, x17, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x11, x19, x11, ror #15
        bic x19, x2, x8, ror #26
        eor x17, x19, x17, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x28, x2, ror #7
        eor x8, x19, x8, ror #33
        mov x28, x25
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x30
        bic x19, x9, x30, ror #17
        eor x25, x19, x25, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x15, x9, ror #7
        eor x30, x19, x30, ror #24
        bic x19, x22, x15, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x9, x19, x9, ror #45
        bic x19, x28, x22, ror #61
        eor x15, x19, x15, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x28, ror #5
        eor x22, x19, x22, ror #2
        mov x2, x26
        xar v3.2d, v18.2d, v27.2d, #43
        mov x28, x21
        bic x19, x14, x21, ror #10
        eor x26, x26, x19
        bic x19, x24, x14, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x21, x19, x21, ror #8
        bic x19, x7, x24, ror #4
        eor x14, x19, x14, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x7, ror #62
        eor x24, x19, x24, ror #2
        bic x19, x28, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x7, x19, x7, ror #52
        ldr x28, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x28
        eor x28, x27, x2, ror #3
        eor x28, x28, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x28, x28, x25, ror #14
        eor x28, x28, x26, ror #24
        eor x19, x23, x20, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x5, ror #51
        eor x19, x19, x30, ror #3
        eor x19, x19, x21, ror #22
        mov v30.16b, v1.16b
        str x26, [sp, #104]
        eor x26, x3, x10, ror #24
        eor x26, x26, x11, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x26, x26, x9, ror #8
        eor x26, x26, x14, ror #61
        str x27, [sp, #96]
        eor x27, x17, x16, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x27, x27, x12, ror #38
        eor x27, x27, x15, ror #13
        eor x27, x27, x24, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x25, [sp, #88]
        eor x25, x7, x4, ror #10
        eor x25, x25, x6, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x25, x25, x8, ror #46
        eor x25, x25, x22, ror #61
        str x13, [sp, #80]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x26, x28, ror #40
        eor x23, x13, x23, ror #44
        eor x20, x13, x20, ror #19
        mov v29.16b, v5.16b
        eor x5, x13, x5, ror #31
        eor x30, x13, x30, ror #47
        eor x21, x13, x21, ror #2
        mov v30.16b, v6.16b
        eor x13, x27, x19, ror #46
        eor x10, x13, x10, ror #27
        eor x3, x13, x3, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x11, x13, x11, ror #27
        eor x9, x13, x9, ror #11
        eor x14, x13, x14
        eor x13, x19, x25, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x26, x25, ror #8
        eor x16, x19, x16, ror #42
        eor x12, x19, x12, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x17, x19, x17, ror #62
        eor x15, x19, x15, ror #11
        eor x24, x19, x24, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x26, x28, x27, ror #24
        eor x4, x26, x4, ror #45
        eor x6, x26, x6, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x8, x26, x8, ror #17
        eor x22, x26, x22, ror #32
        eor x7, x26, x7, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x25, [sp, #96]
        eor x25, x13, x25, ror #61
        mov v30.16b, v11.16b
        ldr x26, [sp, #80]
        eor x26, x13, x26, ror #61
        ldr x27, [sp, #88]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x27, x13, x27, ror #11
        ldr x28, [sp, #104]
        eor x28, x13, x28, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x20
        str x23, [sp, #104]
        bic x23, x11, x20, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x23, ror #40
        bic x23, x15, x11, ror #39
        eor x20, x23, x20, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x23, x7, x15, ror #19
        eor x11, x23, x11, ror #58
        bic x23, x13, x7, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x15, x23, x15, ror #1
        bic x23, x19, x13, ror #23
        eor x7, x23, x7, ror #5
        mov v29.16b, v15.16b
        mov x19, x16
        mov x13, x6
        bic x23, x26, x6, ror #43
        mov v30.16b, v16.16b
        eor x16, x23, x16, ror #61
        bic x23, x30, x26, ror #21
        eor x6, x6, x23
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x23, x14, x30, ror #18
        eor x26, x23, x26, ror #39
        bic x23, x19, x14, ror #28
        eor x30, x23, x30, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x23, x13, x19, ror #18
        eor x14, x23, x14, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x23, x3
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x17, x3, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x22, x17, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x3, x2, x3, ror #25
        bic x2, x28, x22, ror #6
        eor x17, x2, x17, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x28, ror #26
        eor x22, x2, x22, ror #32
        bic x2, x23, x19, ror #7
        mov v30.16b, v21.16b
        eor x28, x2, x28, ror #33
        mov x23, x4
        mov x19, x25
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x5, x25, ror #17
        eor x4, x2, x4, ror #22
        bic x2, x9, x5, ror #7
        eor x25, x2, x25, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x24, x9, ror #38
        eor x5, x2, x5, ror #45
        bic x2, x23, x24, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x9, x2, x9, ror #35
        bic x2, x19, x23, ror #5
        eor x24, x2, x24, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x10
        mov x23, x12
        bic x2, x8, x12, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x10, x10, x2
        bic x2, x27, x8, ror #62
        eor x12, x2, x12, ror #8
        ldr d31, [x1, #-32]
        bic x2, x21, x27, ror #4
        eor x8, x2, x8, ror #2
        bic x2, x19, x21, ror #62
        dup v31.2d, v31.d[0]
        eor x27, x2, x27, ror #2
        bic x2, x23, x19, ror #54
        eor x21, x2, x21, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x23, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x23
        eor x23, x16, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x23, x23, x13
        eor x23, x23, x4, ror #14
        eor x23, x23, x10, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x20, x6, ror #39
        eor x2, x2, x3, ror #51
        eor x2, x2, x25, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x12, ror #22
        str x10, [sp, #104]
        eor x10, x26, x11, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x10, x10, x17, ror #24
        eor x10, x10, x5, ror #8
        eor x10, x10, x8, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x16, [sp, #88]
        eor x16, x22, x15, ror #44
        eor x16, x16, x30, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x16, x16, x9, ror #13
        eor x16, x16, x27, ror #1
        str x4, [sp, #80]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x4, x21, x7, ror #10
        eor x4, x4, x14, ror #9
        eor x4, x4, x28, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x4, x4, x24, ror #61
        str x13, [sp, #96]
        eor x13, x10, x23, ror #40
        eor x20, x13, x20, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x6, x13, x6, ror #19
        eor x3, x13, x3, ror #31
        eor x25, x13, x25, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x12, x13, x12, ror #2
        eor x13, x16, x2, ror #46
        eor x11, x13, x11, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x26, x13, x26, ror #3
        eor x17, x13, x17, ror #27
        eor x5, x13, x5, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x8, x13, x8
        eor x13, x2, x4, ror #31
        eor x2, x10, x4, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x15, x2, x15, ror #42
        eor x30, x2, x30, ror #36
        eor x22, x2, x22, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x9, x2, x9, ror #11
        eor x27, x2, x27, ror #63
        eor x10, x23, x16, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x7, x10, x7, ror #45
        eor x14, x10, x14, ror #44
        eor x28, x10, x28, ror #17
        eor x24, x10, x24, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x21, x10, x21, ror #35
        eor x19, x13, x19
        ldr x4, [sp, #88]
        mov v25.16b, v1.16b
        eor x4, x13, x4, ror #61
        ldr x10, [sp, #96]
        eor x10, x13, x10, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x16, [sp, #80]
        eor x16, x13, x16, ror #11
        ldr x23, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x23, x13, x23, ror #21
        mov x13, x19
        mov x2, x6
        xar v9.2d, v22.2d, v31.2d, #3
        str x20, [sp, #104]
        bic x20, x17, x6, ror #1
        eor x19, x19, x20, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x20, x9, x17, ror #39
        eor x6, x20, x6, ror #40
        bic x20, x21, x9, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x17, x20, x17, ror #58
        bic x20, x13, x21, ror #46
        eor x9, x20, x9, ror #1
        bic x20, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x21, x20, x21, ror #5
        mov x2, x15
        mov x13, x14
        xar v2.2d, v12.2d, v31.2d, #21
        bic x20, x10, x14, ror #43
        eor x15, x20, x15, ror #61
        bic x20, x25, x10, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x14, x14, x20
        bic x20, x8, x25, ror #18
        eor x10, x20, x10, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x20, x2, x8, ror #28
        eor x25, x20, x25, ror #46
        bic x20, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x8, x20, x8, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x20, x26
        str x19, [sp, #104]
        bic x19, x22, x26, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x24, x22, ror #9
        eor x26, x19, x26, ror #25
        bic x19, x23, x24, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x22, x19, x22, ror #15
        bic x19, x2, x23, ror #26
        eor x24, x19, x24, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x20, x2, ror #7
        eor x23, x19, x23, ror #33
        mov x20, x7
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x4
        bic x19, x3, x4, ror #17
        eor x7, x19, x7, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x5, x3, ror #7
        eor x4, x19, x4, ror #24
        bic x19, x27, x5, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x3, x19, x3, ror #45
        bic x19, x20, x27, ror #61
        eor x5, x19, x5, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x20, ror #5
        eor x27, x19, x27, ror #2
        mov x2, x11
        xar v3.2d, v18.2d, v27.2d, #43
        mov x20, x30
        bic x19, x28, x30, ror #10
        eor x11, x11, x19
        bic x19, x16, x28, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x30, x19, x30, ror #8
        bic x19, x12, x16, ror #4
        eor x28, x19, x28, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x12, ror #62
        eor x16, x19, x16, ror #2
        bic x19, x20, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x12, x19, x12, ror #52
        ldr x20, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x20
        eor x20, x15, x2, ror #3
        eor x20, x20, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x20, x20, x7, ror #14
        eor x20, x20, x11, ror #24
        eor x19, x6, x14, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x26, ror #51
        eor x19, x19, x4, ror #3
        eor x19, x19, x30, ror #22
        mov v30.16b, v1.16b
        str x11, [sp, #104]
        eor x11, x10, x17, ror #24
        eor x11, x11, x22, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x11, x11, x3, ror #8
        eor x11, x11, x28, ror #61
        str x15, [sp, #80]
        eor x15, x24, x9, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x15, x15, x25, ror #38
        eor x15, x15, x5, ror #13
        eor x15, x15, x16, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x7, [sp, #96]
        eor x7, x12, x21, ror #10
        eor x7, x7, x8, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x7, x7, x23, ror #46
        eor x7, x7, x27, ror #61
        str x13, [sp, #88]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x11, x20, ror #40
        eor x6, x13, x6, ror #44
        eor x14, x13, x14, ror #19
        mov v29.16b, v5.16b
        eor x26, x13, x26, ror #31
        eor x4, x13, x4, ror #47
        eor x30, x13, x30, ror #2
        mov v30.16b, v6.16b
        eor x13, x15, x19, ror #46
        eor x17, x13, x17, ror #27
        eor x10, x13, x10, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x22, x13, x22, ror #27
        eor x3, x13, x3, ror #11
        eor x28, x13, x28
        eor x13, x19, x7, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x11, x7, ror #8
        eor x9, x19, x9, ror #42
        eor x25, x19, x25, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x24, x19, x24, ror #62
        eor x5, x19, x5, ror #11
        eor x16, x19, x16, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x11, x20, x15, ror #24
        eor x21, x11, x21, ror #45
        eor x8, x11, x8, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x23, x11, x23, ror #17
        eor x27, x11, x27, ror #32
        eor x12, x11, x12, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x7, [sp, #80]
        eor x7, x13, x7, ror #61
        mov v30.16b, v11.16b
        ldr x11, [sp, #88]
        eor x11, x13, x11, ror #61
        ldr x15, [sp, #96]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x15, x13, x15, ror #11
        ldr x20, [sp, #104]
        eor x20, x13, x20, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x14
        str x6, [sp, #104]
        bic x6, x22, x14, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x6, ror #40
        bic x6, x5, x22, ror #39
        eor x14, x6, x14, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x6, x12, x5, ror #19
        eor x22, x6, x22, ror #58
        bic x6, x13, x12, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x5, x6, x5, ror #1
        bic x6, x19, x13, ror #23
        eor x12, x6, x12, ror #5
        mov v29.16b, v15.16b
        mov x19, x9
        mov x13, x8
        bic x6, x11, x8, ror #43
        mov v30.16b, v16.16b
        eor x9, x6, x9, ror #61
        bic x6, x4, x11, ror #21
        eor x8, x8, x6
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x6, x28, x4, ror #18
        eor x11, x6, x11, ror #39
        bic x6, x19, x28, ror #28
        eor x4, x6, x4, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x6, x13, x19, ror #18
        eor x28, x6, x28, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x6, x10
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x24, x10, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x27, x24, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x10, x2, x10, ror #25
        bic x2, x20, x27, ror #6
        eor x24, x2, x24, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x20, ror #26
        eor x27, x2, x27, ror #32
        bic x2, x6, x19, ror #7
        mov v30.16b, v21.16b
        eor x20, x2, x20, ror #33
        mov x6, x21
        mov x19, x7
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x26, x7, ror #17
        eor x21, x2, x21, ror #22
        bic x2, x3, x26, ror #7
        eor x7, x2, x7, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x16, x3, ror #38
        eor x26, x2, x26, ror #45
        bic x2, x6, x16, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x3, x2, x3, ror #35
        bic x2, x19, x6, ror #5
        eor x16, x2, x16, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x17
        mov x6, x25
        bic x2, x23, x25, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x17, x17, x2
        bic x2, x15, x23, ror #62
        eor x25, x2, x25, ror #8
        ldr d31, [x1, #-40]
        bic x2, x30, x15, ror #4
        eor x23, x2, x23, ror #2
        bic x2, x19, x30, ror #62
        dup v31.2d, v31.d[0]
        eor x15, x2, x15, ror #2
        bic x2, x6, x19, ror #54
        eor x30, x2, x30, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x6, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x6
        eor x6, x9, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x6, x6, x13
        eor x6, x6, x21, ror #14
        eor x6, x6, x17, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x14, x8, ror #39
        eor x2, x2, x10, ror #51
        eor x2, x2, x7, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x25, ror #22
        str x17, [sp, #104]
        eor x17, x11, x22, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x17, x17, x24, ror #24
        eor x17, x17, x26, ror #8
        eor x17, x17, x23, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x9, [sp, #96]
        eor x9, x27, x5, ror #44
        eor x9, x9, x4, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x9, x9, x3, ror #13
        eor x9, x9, x15, ror #1
        str x21, [sp, #88]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x21, x30, x12, ror #10
        eor x21, x21, x28, ror #9
        eor x21, x21, x20, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x21, x21, x16, ror #61
        str x13, [sp, #80]
        eor x13, x17, x6, ror #40
        eor x14, x13, x14, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x8, x13, x8, ror #19
        eor x10, x13, x10, ror #31
        eor x7, x13, x7, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x25, x13, x25, ror #2
        eor x13, x9, x2, ror #46
        eor x22, x13, x22, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x11, x13, x11, ror #3
        eor x24, x13, x24, ror #27
        eor x26, x13, x26, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x23, x13, x23
        eor x13, x2, x21, ror #31
        eor x2, x17, x21, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x5, x2, x5, ror #42
        eor x4, x2, x4, ror #36
        eor x27, x2, x27, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x3, x2, x3, ror #11
        eor x15, x2, x15, ror #63
        eor x17, x6, x9, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x12, x17, x12, ror #45
        eor x28, x17, x28, ror #44
        eor x20, x17, x20, ror #17
        eor x16, x17, x16, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x30, x17, x30, ror #35
        eor x19, x13, x19
        ldr x21, [sp, #96]
        mov v25.16b, v1.16b
        eor x21, x13, x21, ror #61
        ldr x17, [sp, #80]
        eor x17, x13, x17, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x9, [sp, #88]
        eor x9, x13, x9, ror #11
        ldr x6, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x6, x13, x6, ror #21
        mov x13, x19
        mov x2, x8
        xar v9.2d, v22.2d, v31.2d, #3
        str x14, [sp, #104]
        bic x14, x24, x8, ror #1
        eor x19, x19, x14, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x14, x3, x24, ror #39
        eor x8, x14, x8, ror #40
        bic x14, x30, x3, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x24, x14, x24, ror #58
        bic x14, x13, x30, ror #46
        eor x3, x14, x3, ror #1
        bic x14, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x30, x14, x30, ror #5
        mov x2, x5
        mov x13, x28
        xar v2.2d, v12.2d, v31.2d, #21
        bic x14, x17, x28, ror #43
        eor x5, x14, x5, ror #61
        bic x14, x7, x17, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x28, x28, x14
        bic x14, x23, x7, ror #18
        eor x17, x14, x17, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x14, x2, x23, ror #28
        eor x7, x14, x7, ror #46
        bic x14, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x23, x14, x23, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x14, x11
        str x19, [sp, #104]
        bic x19, x27, x11, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x16, x27, ror #9
        eor x11, x19, x11, ror #25
        bic x19, x6, x16, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x27, x19, x27, ror #15
        bic x19, x2, x6, ror #26
        eor x16, x19, x16, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x14, x2, ror #7
        eor x6, x19, x6, ror #33
        mov x14, x12
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x21
        bic x19, x10, x21, ror #17
        eor x12, x19, x12, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x26, x10, ror #7
        eor x21, x19, x21, ror #24
        bic x19, x15, x26, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x10, x19, x10, ror #45
        bic x19, x14, x15, ror #61
        eor x26, x19, x26, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x14, ror #5
        eor x15, x19, x15, ror #2
        mov x2, x22
        xar v3.2d, v18.2d, v27.2d, #43
        mov x14, x4
        bic x19, x20, x4, ror #10
        eor x22, x22, x19
        bic x19, x9, x20, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x4, x19, x4, ror #8
        bic x19, x25, x9, ror #4
        eor x20, x19, x20, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x25, ror #62
        eor x9, x19, x9, ror #2
        bic x19, x14, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x25, x19, x25, ror #52
        ldr x14, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x14
        eor x14, x5, x2, ror #3
        eor x14, x14, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x14, x14, x12, ror #14
        eor x14, x14, x22, ror #24
        eor x19, x8, x28, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x11, ror #51
        eor x19, x19, x21, ror #3
        eor x19, x19, x4, ror #22
        mov v30.16b, v1.16b
        str x22, [sp, #104]
        eor x22, x17, x24, ror #24
        eor x22, x22, x27, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x22, x22, x10, ror #8
        eor x22, x22, x20, ror #61
        str x5, [sp, #88]
        eor x5, x16, x3, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x5, x5, x7, ror #38
        eor x5, x5, x26, ror #13
        eor x5, x5, x9, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x12, [sp, #80]
        eor x12, x25, x30, ror #10
        eor x12, x12, x23, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x12, x12, x6, ror #46
        eor x12, x12, x15, ror #61
        str x13, [sp, #96]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x22, x14, ror #40
        eor x8, x13, x8, ror #44
        eor x28, x13, x28, ror #19
        mov v29.16b, v5.16b
        eor x11, x13, x11, ror #31
        eor x21, x13, x21, ror #47
        eor x4, x13, x4, ror #2
        mov v30.16b, v6.16b
        eor x13, x5, x19, ror #46
        eor x24, x13, x24, ror #27
        eor x17, x13, x17, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x27, x13, x27, ror #27
        eor x10, x13, x10, ror #11
        eor x20, x13, x20
        eor x13, x19, x12, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x22, x12, ror #8
        eor x3, x19, x3, ror #42
        eor x7, x19, x7, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x16, x19, x16, ror #62
        eor x26, x19, x26, ror #11
        eor x9, x19, x9, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x22, x14, x5, ror #24
        eor x30, x22, x30, ror #45
        eor x23, x22, x23, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x6, x22, x6, ror #17
        eor x15, x22, x15, ror #32
        eor x25, x22, x25, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x12, [sp, #88]
        eor x12, x13, x12, ror #61
        mov v30.16b, v11.16b
        ldr x22, [sp, #96]
        eor x22, x13, x22, ror #61
        ldr x5, [sp, #80]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x5, x13, x5, ror #11
        ldr x14, [sp, #104]
        eor x14, x13, x14, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x28
        str x8, [sp, #104]
        bic x8, x27, x28, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x8, ror #40
        bic x8, x26, x27, ror #39
        eor x28, x8, x28, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x8, x25, x26, ror #19
        eor x27, x8, x27, ror #58
        bic x8, x13, x25, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x26, x8, x26, ror #1
        bic x8, x19, x13, ror #23
        eor x25, x8, x25, ror #5
        mov v29.16b, v15.16b
        mov x19, x3
        mov x13, x23
        bic x8, x22, x23, ror #43
        mov v30.16b, v16.16b
        eor x3, x8, x3, ror #61
        bic x8, x21, x22, ror #21
        eor x23, x23, x8
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x8, x20, x21, ror #18
        eor x22, x8, x22, ror #39
        bic x8, x19, x20, ror #28
        eor x21, x8, x21, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x8, x13, x19, ror #18
        eor x20, x8, x20, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x8, x17
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x16, x17, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x15, x16, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x17, x2, x17, ror #25
        bic x2, x14, x15, ror #6
        eor x16, x2, x16, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x14, ror #26
        eor x15, x2, x15, ror #32
        bic x2, x8, x19, ror #7
        mov v30.16b, v21.16b
        eor x14, x2, x14, ror #33
        mov x8, x30
        mov x19, x12
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x11, x12, ror #17
        eor x30, x2, x30, ror #22
        bic x2, x10, x11, ror #7
        eor x12, x2, x12, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x9, x10, ror #38
        eor x11, x2, x11, ror #45
        bic x2, x8, x9, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x10, x2, x10, ror #35
        bic x2, x19, x8, ror #5
        eor x9, x2, x9, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x24
        mov x8, x7
        bic x2, x6, x7, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x24, x24, x2
        bic x2, x5, x6, ror #62
        eor x7, x2, x7, ror #8
        ldr d31, [x1, #-48]
        bic x2, x4, x5, ror #4
        eor x6, x2, x6, ror #2
        bic x2, x19, x4, ror #62
        dup v31.2d, v31.d[0]
        eor x5, x2, x5, ror #2
        bic x2, x8, x19, ror #54
        eor x4, x2, x4, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x8, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x8
        eor x8, x3, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x8, x8, x13
        eor x8, x8, x30, ror #14
        eor x8, x8, x24, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x28, x23, ror #39
        eor x2, x2, x17, ror #51
        eor x2, x2, x12, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x7, ror #22
        str x24, [sp, #104]
        eor x24, x22, x27, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x24, x24, x16, ror #24
        eor x24, x24, x11, ror #8
        eor x24, x24, x6, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x3, [sp, #80]
        eor x3, x15, x26, ror #44
        eor x3, x3, x21, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x3, x3, x10, ror #13
        eor x3, x3, x5, ror #1
        str x30, [sp, #96]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x30, x4, x25, ror #10
        eor x30, x30, x20, ror #9
        eor x30, x30, x14, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x30, x30, x9, ror #61
        str x13, [sp, #88]
        eor x13, x24, x8, ror #40
        eor x28, x13, x28, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x23, x13, x23, ror #19
        eor x17, x13, x17, ror #31
        eor x12, x13, x12, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x7, x13, x7, ror #2
        eor x13, x3, x2, ror #46
        eor x27, x13, x27, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x22, x13, x22, ror #3
        eor x16, x13, x16, ror #27
        eor x11, x13, x11, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x6, x13, x6
        eor x13, x2, x30, ror #31
        eor x2, x24, x30, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x26, x2, x26, ror #42
        eor x21, x2, x21, ror #36
        eor x15, x2, x15, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x10, x2, x10, ror #11
        eor x5, x2, x5, ror #63
        eor x24, x8, x3, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x25, x24, x25, ror #45
        eor x20, x24, x20, ror #44
        eor x14, x24, x14, ror #17
        eor x9, x24, x9, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x4, x24, x4, ror #35
        eor x19, x13, x19
        ldr x30, [sp, #80]
        mov v25.16b, v1.16b
        eor x30, x13, x30, ror #61
        ldr x24, [sp, #88]
        eor x24, x13, x24, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x3, [sp, #96]
        eor x3, x13, x3, ror #11
        ldr x8, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x8, x13, x8, ror #21
        mov x13, x19
        mov x2, x23
        xar v9.2d, v22.2d, v31.2d, #3
        str x28, [sp, #104]
        bic x28, x16, x23, ror #1
        eor x19, x19, x28, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x28, x10, x16, ror #39
        eor x23, x28, x23, ror #40
        bic x28, x4, x10, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x16, x28, x16, ror #58
        bic x28, x13, x4, ror #46
        eor x10, x28, x10, ror #1
        bic x28, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x4, x28, x4, ror #5
        mov x2, x26
        mov x13, x20
        xar v2.2d, v12.2d, v31.2d, #21
        bic x28, x24, x20, ror #43
        eor x26, x28, x26, ror #61
        bic x28, x12, x24, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x20, x20, x28
        bic x28, x6, x12, ror #18
        eor x24, x28, x24, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x28, x2, x6, ror #28
        eor x12, x28, x12, ror #46
        bic x28, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x6, x28, x6, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x28, x22
        str x19, [sp, #104]
        bic x19, x15, x22, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x9, x15, ror #9
        eor x22, x19, x22, ror #25
        bic x19, x8, x9, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x15, x19, x15, ror #15
        bic x19, x2, x8, ror #26
        eor x9, x19, x9, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x28, x2, ror #7
        eor x8, x19, x8, ror #33
        mov x28, x25
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x30
        bic x19, x17, x30, ror #17
        eor x25, x19, x25, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x11, x17, ror #7
        eor x30, x19, x30, ror #24
        bic x19, x5, x11, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x17, x19, x17, ror #45
        bic x19, x28, x5, ror #61
        eor x11, x19, x11, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x28, ror #5
        eor x5, x19, x5, ror #2
        mov x2, x27
        xar v3.2d, v18.2d, v27.2d, #43
        mov x28, x21
        bic x19, x14, x21, ror #10
        eor x27, x27, x19
        bic x19, x3, x14, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x21, x19, x21, ror #8
        bic x19, x7, x3, ror #4
        eor x14, x19, x14, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x7, ror #62
        eor x3, x19, x3, ror #2
        bic x19, x28, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x7, x19, x7, ror #52
        ldr x28, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x28
        eor x28, x26, x2, ror #3
        eor x28, x28, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x28, x28, x25, ror #14
        eor x28, x28, x27, ror #24
        eor x19, x23, x20, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x22, ror #51
        eor x19, x19, x30, ror #3
        eor x19, x19, x21, ror #22
        mov v30.16b, v1.16b
        str x27, [sp, #104]
        eor x27, x24, x16, ror #24
        eor x27, x27, x15, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x27, x27, x17, ror #8
        eor x27, x27, x14, ror #61
        str x26, [sp, #96]
        eor x26, x9, x10, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x26, x26, x12, ror #38
        eor x26, x26, x11, ror #13
        eor x26, x26, x3, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x25, [sp, #88]
        eor x25, x7, x4, ror #10
        eor x25, x25, x6, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x25, x25, x8, ror #46
        eor x25, x25, x5, ror #61
        str x13, [sp, #80]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x27, x28, ror #40
        eor x23, x13, x23, ror #44
        eor x20, x13, x20, ror #19
        mov v29.16b, v5.16b
        eor x22, x13, x22, ror #31
        eor x30, x13, x30, ror #47
        eor x21, x13, x21, ror #2
        mov v30.16b, v6.16b
        eor x13, x26, x19, ror #46
        eor x16, x13, x16, ror #27
        eor x24, x13, x24, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x15, x13, x15, ror #27
        eor x17, x13, x17, ror #11
        eor x14, x13, x14
        eor x13, x19, x25, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x27, x25, ror #8
        eor x10, x19, x10, ror #42
        eor x12, x19, x12, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x9, x19, x9, ror #62
        eor x11, x19, x11, ror #11
        eor x3, x19, x3, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x27, x28, x26, ror #24
        eor x4, x27, x4, ror #45
        eor x6, x27, x6, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x8, x27, x8, ror #17
        eor x5, x27, x5, ror #32
        eor x7, x27, x7, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x25, [sp, #96]
        eor x25, x13, x25, ror #61
        mov v30.16b, v11.16b
        ldr x27, [sp, #80]
        eor x27, x13, x27, ror #61
        ldr x26, [sp, #88]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x26, x13, x26, ror #11
        ldr x28, [sp, #104]
        eor x28, x13, x28, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x20
        str x23, [sp, #104]
        bic x23, x15, x20, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x23, ror #40
        bic x23, x11, x15, ror #39
        eor x20, x23, x20, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x23, x7, x11, ror #19
        eor x15, x23, x15, ror #58
        bic x23, x13, x7, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x11, x23, x11, ror #1
        bic x23, x19, x13, ror #23
        eor x7, x23, x7, ror #5
        mov v29.16b, v15.16b
        mov x19, x10
        mov x13, x6
        bic x23, x27, x6, ror #43
        mov v30.16b, v16.16b
        eor x10, x23, x10, ror #61
        bic x23, x30, x27, ror #21
        eor x6, x6, x23
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x23, x14, x30, ror #18
        eor x27, x23, x27, ror #39
        bic x23, x19, x14, ror #28
        eor x30, x23, x30, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x23, x13, x19, ror #18
        eor x14, x23, x14, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x23, x24
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x9, x24, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x5, x9, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x24, x2, x24, ror #25
        bic x2, x28, x5, ror #6
        eor x9, x2, x9, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x28, ror #26
        eor x5, x2, x5, ror #32
        bic x2, x23, x19, ror #7
        mov v30.16b, v21.16b
        eor x28, x2, x28, ror #33
        mov x23, x4
        mov x19, x25
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x22, x25, ror #17
        eor x4, x2, x4, ror #22
        bic x2, x17, x22, ror #7
        eor x25, x2, x25, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x3, x17, ror #38
        eor x22, x2, x22, ror #45
        bic x2, x23, x3, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x17, x2, x17, ror #35
        bic x2, x19, x23, ror #5
        eor x3, x2, x3, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x16
        mov x23, x12
        bic x2, x8, x12, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x16, x16, x2
        bic x2, x26, x8, ror #62
        eor x12, x2, x12, ror #8
        ldr d31, [x1, #-56]
        bic x2, x21, x26, ror #4
        eor x8, x2, x8, ror #2
        bic x2, x19, x21, ror #62
        dup v31.2d, v31.d[0]
        eor x26, x2, x26, ror #2
        bic x2, x23, x19, ror #54
        eor x21, x2, x21, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x23, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x23
        eor x23, x10, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x23, x23, x13
        eor x23, x23, x4, ror #14
        eor x23, x23, x16, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x20, x6, ror #39
        eor x2, x2, x24, ror #51
        eor x2, x2, x25, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x12, ror #22
        str x16, [sp, #104]
        eor x16, x27, x15, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x16, x16, x9, ror #24
        eor x16, x16, x22, ror #8
        eor x16, x16, x8, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x10, [sp, #88]
        eor x10, x5, x11, ror #44
        eor x10, x10, x30, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x10, x10, x17, ror #13
        eor x10, x10, x26, ror #1
        str x4, [sp, #80]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x4, x21, x7, ror #10
        eor x4, x4, x14, ror #9
        eor x4, x4, x28, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x4, x4, x3, ror #61
        str x13, [sp, #96]
        eor x13, x16, x23, ror #40
        eor x20, x13, x20, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x6, x13, x6, ror #19
        eor x24, x13, x24, ror #31
        eor x25, x13, x25, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x12, x13, x12, ror #2
        eor x13, x10, x2, ror #46
        eor x15, x13, x15, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x27, x13, x27, ror #3
        eor x9, x13, x9, ror #27
        eor x22, x13, x22, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x8, x13, x8
        eor x13, x2, x4, ror #31
        eor x2, x16, x4, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x11, x2, x11, ror #42
        eor x30, x2, x30, ror #36
        eor x5, x2, x5, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x17, x2, x17, ror #11
        eor x26, x2, x26, ror #63
        eor x16, x23, x10, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x7, x16, x7, ror #45
        eor x14, x16, x14, ror #44
        eor x28, x16, x28, ror #17
        eor x3, x16, x3, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x21, x16, x21, ror #35
        eor x19, x13, x19
        ldr x4, [sp, #88]
        mov v25.16b, v1.16b
        eor x4, x13, x4, ror #61
        ldr x16, [sp, #96]
        eor x16, x13, x16, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x10, [sp, #80]
        eor x10, x13, x10, ror #11
        ldr x23, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x23, x13, x23, ror #21
        mov x13, x19
        mov x2, x6
        xar v9.2d, v22.2d, v31.2d, #3
        str x20, [sp, #104]
        bic x20, x9, x6, ror #1
        eor x19, x19, x20, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x20, x17, x9, ror #39
        eor x6, x20, x6, ror #40
        bic x20, x21, x17, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x9, x20, x9, ror #58
        bic x20, x13, x21, ror #46
        eor x17, x20, x17, ror #1
        bic x20, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x21, x20, x21, ror #5
        mov x2, x11
        mov x13, x14
        xar v2.2d, v12.2d, v31.2d, #21
        bic x20, x16, x14, ror #43
        eor x11, x20, x11, ror #61
        bic x20, x25, x16, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x14, x14, x20
        bic x20, x8, x25, ror #18
        eor x16, x20, x16, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x20, x2, x8, ror #28
        eor x25, x20, x25, ror #46
        bic x20, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x8, x20, x8, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x20, x27
        str x19, [sp, #104]
        bic x19, x5, x27, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x3, x5, ror #9
        eor x27, x19, x27, ror #25
        bic x19, x23, x3, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x5, x19, x5, ror #15
        bic x19, x2, x23, ror #26
        eor x3, x19, x3, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x20, x2, ror #7
        eor x23, x19, x23, ror #33
        mov x20, x7
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x4
        bic x19, x24, x4, ror #17
        eor x7, x19, x7, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x22, x24, ror #7
        eor x4, x19, x4, ror #24
        bic x19, x26, x22, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x24, x19, x24, ror #45
        bic x19, x20, x26, ror #61
        eor x22, x19, x22, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x20, ror #5
        eor x26, x19, x26, ror #2
        mov x2, x15
        xar v3.2d, v18.2d, v27.2d, #43
        mov x20, x30
        bic x19, x28, x30, ror #10
        eor x15, x15, x19
        bic x19, x10, x28, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x30, x19, x30, ror #8
        bic x19, x12, x10, ror #4
        eor x28, x19, x28, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x12, ror #62
        eor x10, x19, x10, ror #2
        bic x19, x20, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x12, x19, x12, ror #52
        ldr x20, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x20
        eor x20, x11, x2, ror #3
        eor x20, x20, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x20, x20, x7, ror #14
        eor x20, x20, x15, ror #24
        eor x19, x6, x14, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x27, ror #51
        eor x19, x19, x4, ror #3
        eor x19, x19, x30, ror #22
        mov v30.16b, v1.16b
        str x15, [sp, #104]
        eor x15, x16, x9, ror #24
        eor x15, x15, x5, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x15, x15, x24, ror #8
        eor x15, x15, x28, ror #61
        str x11, [sp, #80]
        eor x11, x3, x17, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x11, x11, x25, ror #38
        eor x11, x11, x22, ror #13
        eor x11, x11, x10, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x7, [sp, #96]
        eor x7, x12, x21, ror #10
        eor x7, x7, x8, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x7, x7, x23, ror #46
        eor x7, x7, x26, ror #61
        str x13, [sp, #88]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x15, x20, ror #40
        eor x6, x13, x6, ror #44
        eor x14, x13, x14, ror #19
        mov v29.16b, v5.16b
        eor x27, x13, x27, ror #31
        eor x4, x13, x4, ror #47
        eor x30, x13, x30, ror #2
        mov v30.16b, v6.16b
        eor x13, x11, x19, ror #46
        eor x9, x13, x9, ror #27
        eor x16, x13, x16, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x5, x13, x5, ror #27
        eor x24, x13, x24, ror #11
        eor x28, x13, x28
        eor x13, x19, x7, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x15, x7, ror #8
        eor x17, x19, x17, ror #42
        eor x25, x19, x25, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x3, x19, x3, ror #62
        eor x22, x19, x22, ror #11
        eor x10, x19, x10, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x15, x20, x11, ror #24
        eor x21, x15, x21, ror #45
        eor x8, x15, x8, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x23, x15, x23, ror #17
        eor x26, x15, x26, ror #32
        eor x12, x15, x12, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x7, [sp, #80]
        eor x7, x13, x7, ror #61
        mov v30.16b, v11.16b
        ldr x15, [sp, #88]
        eor x15, x13, x15, ror #61
        ldr x11, [sp, #96]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x11, x13, x11, ror #11
        ldr x20, [sp, #104]
        eor x20, x13, x20, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x14
        str x6, [sp, #104]
        bic x6, x5, x14, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x6, ror #40
        bic x6, x22, x5, ror #39
        eor x14, x6, x14, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x6, x12, x22, ror #19
        eor x5, x6, x5, ror #58
        bic x6, x13, x12, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x22, x6, x22, ror #1
        bic x6, x19, x13, ror #23
        eor x12, x6, x12, ror #5
        mov v29.16b, v15.16b
        mov x19, x17
        mov x13, x8
        bic x6, x15, x8, ror #43
        mov v30.16b, v16.16b
        eor x17, x6, x17, ror #61
        bic x6, x4, x15, ror #21
        eor x8, x8, x6
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x6, x28, x4, ror #18
        eor x15, x6, x15, ror #39
        bic x6, x19, x28, ror #28
        eor x4, x6, x4, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x6, x13, x19, ror #18
        eor x28, x6, x28, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x6, x16
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x3, x16, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x26, x3, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x16, x2, x16, ror #25
        bic x2, x20, x26, ror #6
        eor x3, x2, x3, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x20, ror #26
        eor x26, x2, x26, ror #32
        bic x2, x6, x19, ror #7
        mov v30.16b, v21.16b
        eor x20, x2, x20, ror #33
        mov x6, x21
        mov x19, x7
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x27, x7, ror #17
        eor x21, x2, x21, ror #22
        bic x2, x24, x27, ror #7
        eor x7, x2, x7, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x10, x24, ror #38
        eor x27, x2, x27, ror #45
        bic x2, x6, x10, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x24, x2, x24, ror #35
        bic x2, x19, x6, ror #5
        eor x10, x2, x10, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x9
        mov x6, x25
        bic x2, x23, x25, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x9, x9, x2
        bic x2, x11, x23, ror #62
        eor x25, x2, x25, ror #8
        ldr d31, [x1, #-64]
        bic x2, x30, x11, ror #4
        eor x23, x2, x23, ror #2
        bic x2, x19, x30, ror #62
        dup v31.2d, v31.d[0]
        eor x11, x2, x11, ror #2
        bic x2, x6, x19, ror #54
        eor x30, x2, x30, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x6, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x6
        eor x6, x17, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x6, x6, x13
        eor x6, x6, x21, ror #14
        eor x6, x6, x9, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x14, x8, ror #39
        eor x2, x2, x16, ror #51
        eor x2, x2, x7, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x25, ror #22
        str x9, [sp, #104]
        eor x9, x15, x5, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x9, x9, x3, ror #24
        eor x9, x9, x27, ror #8
        eor x9, x9, x23, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x17, [sp, #96]
        eor x17, x26, x22, ror #44
        eor x17, x17, x4, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x17, x17, x24, ror #13
        eor x17, x17, x11, ror #1
        str x21, [sp, #88]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x21, x30, x12, ror #10
        eor x21, x21, x28, ror #9
        eor x21, x21, x20, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x21, x21, x10, ror #61
        str x13, [sp, #80]
        eor x13, x9, x6, ror #40
        eor x14, x13, x14, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x8, x13, x8, ror #19
        eor x16, x13, x16, ror #31
        eor x7, x13, x7, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x25, x13, x25, ror #2
        eor x13, x17, x2, ror #46
        eor x5, x13, x5, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x15, x13, x15, ror #3
        eor x3, x13, x3, ror #27
        eor x27, x13, x27, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x23, x13, x23
        eor x13, x2, x21, ror #31
        eor x2, x9, x21, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x22, x2, x22, ror #42
        eor x4, x2, x4, ror #36
        eor x26, x2, x26, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x24, x2, x24, ror #11
        eor x11, x2, x11, ror #63
        eor x9, x6, x17, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x12, x9, x12, ror #45
        eor x28, x9, x28, ror #44
        eor x20, x9, x20, ror #17
        eor x10, x9, x10, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x30, x9, x30, ror #35
        eor x19, x13, x19
        ldr x21, [sp, #96]
        mov v25.16b, v1.16b
        eor x21, x13, x21, ror #61
        ldr x9, [sp, #80]
        eor x9, x13, x9, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x17, [sp, #88]
        eor x17, x13, x17, ror #11
        ldr x6, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x6, x13, x6, ror #21
        mov x13, x19
        mov x2, x8
        xar v9.2d, v22.2d, v31.2d, #3
        str x14, [sp, #104]
        bic x14, x3, x8, ror #1
        eor x19, x19, x14, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x14, x24, x3, ror #39
        eor x8, x14, x8, ror #40
        bic x14, x30, x24, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x3, x14, x3, ror #58
        bic x14, x13, x30, ror #46
        eor x24, x14, x24, ror #1
        bic x14, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x30, x14, x30, ror #5
        mov x2, x22
        mov x13, x28
        xar v2.2d, v12.2d, v31.2d, #21
        bic x14, x9, x28, ror #43
        eor x22, x14, x22, ror #61
        bic x14, x7, x9, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x28, x28, x14
        bic x14, x23, x7, ror #18
        eor x9, x14, x9, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x14, x2, x23, ror #28
        eor x7, x14, x7, ror #46
        bic x14, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x23, x14, x23, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x14, x15
        str x19, [sp, #104]
        bic x19, x26, x15, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x10, x26, ror #9
        eor x15, x19, x15, ror #25
        bic x19, x6, x10, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x26, x19, x26, ror #15
        bic x19, x2, x6, ror #26
        eor x10, x19, x10, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x14, x2, ror #7
        eor x6, x19, x6, ror #33
        mov x14, x12
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x21
        bic x19, x16, x21, ror #17
        eor x12, x19, x12, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x27, x16, ror #7
        eor x21, x19, x21, ror #24
        bic x19, x11, x27, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x16, x19, x16, ror #45
        bic x19, x14, x11, ror #61
        eor x27, x19, x27, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x14, ror #5
        eor x11, x19, x11, ror #2
        mov x2, x5
        xar v3.2d, v18.2d, v27.2d, #43
        mov x14, x4
        bic x19, x20, x4, ror #10
        eor x5, x5, x19
        bic x19, x17, x20, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x4, x19, x4, ror #8
        bic x19, x25, x17, ror #4
        eor x20, x19, x20, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x25, ror #62
        eor x17, x19, x17, ror #2
        bic x19, x14, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x25, x19, x25, ror #52
        ldr x14, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x14
        eor x14, x22, x2, ror #3
        eor x14, x14, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x14, x14, x12, ror #14
        eor x14, x14, x5, ror #24
        eor x19, x8, x28, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x15, ror #51
        eor x19, x19, x21, ror #3
        eor x19, x19, x4, ror #22
        mov v30.16b, v1.16b
        str x5, [sp, #104]
        eor x5, x9, x3, ror #24
        eor x5, x5, x26, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x5, x5, x16, ror #8
        eor x5, x5, x20, ror #61
        str x22, [sp, #88]
        eor x22, x10, x24, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x22, x22, x7, ror #38
        eor x22, x22, x27, ror #13
        eor x22, x22, x17, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x12, [sp, #80]
        eor x12, x25, x30, ror #10
        eor x12, x12, x23, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x12, x12, x6, ror #46
        eor x12, x12, x11, ror #61
        str x13, [sp, #96]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x5, x14, ror #40
        eor x8, x13, x8, ror #44
        eor x28, x13, x28, ror #19
        mov v29.16b, v5.16b
        eor x15, x13, x15, ror #31
        eor x21, x13, x21, ror #47
        eor x4, x13, x4, ror #2
        mov v30.16b, v6.16b
        eor x13, x22, x19, ror #46
        eor x3, x13, x3, ror #27
        eor x9, x13, x9, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x26, x13, x26, ror #27
        eor x16, x13, x16, ror #11
        eor x20, x13, x20
        eor x13, x19, x12, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x5, x12, ror #8
        eor x24, x19, x24, ror #42
        eor x7, x19, x7, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x10, x19, x10, ror #62
        eor x27, x19, x27, ror #11
        eor x17, x19, x17, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x5, x14, x22, ror #24
        eor x30, x5, x30, ror #45
        eor x23, x5, x23, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x6, x5, x6, ror #17
        eor x11, x5, x11, ror #32
        eor x25, x5, x25, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x12, [sp, #88]
        eor x12, x13, x12, ror #61
        mov v30.16b, v11.16b
        ldr x5, [sp, #96]
        eor x5, x13, x5, ror #61
        ldr x22, [sp, #80]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x22, x13, x22, ror #11
        ldr x14, [sp, #104]
        eor x14, x13, x14, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x28
        str x8, [sp, #104]
        bic x8, x26, x28, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x8, ror #40
        bic x8, x27, x26, ror #39
        eor x28, x8, x28, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x8, x25, x27, ror #19
        eor x26, x8, x26, ror #58
        bic x8, x13, x25, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x27, x8, x27, ror #1
        bic x8, x19, x13, ror #23
        eor x25, x8, x25, ror #5
        mov v29.16b, v15.16b
        mov x19, x24
        mov x13, x23
        bic x8, x5, x23, ror #43
        mov v30.16b, v16.16b
        eor x24, x8, x24, ror #61
        bic x8, x21, x5, ror #21
        eor x23, x23, x8
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x8, x20, x21, ror #18
        eor x5, x8, x5, ror #39
        bic x8, x19, x20, ror #28
        eor x21, x8, x21, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x8, x13, x19, ror #18
        eor x20, x8, x20, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x8, x9
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x10, x9, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x11, x10, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x9, x2, x9, ror #25
        bic x2, x14, x11, ror #6
        eor x10, x2, x10, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x14, ror #26
        eor x11, x2, x11, ror #32
        bic x2, x8, x19, ror #7
        mov v30.16b, v21.16b
        eor x14, x2, x14, ror #33
        mov x8, x30
        mov x19, x12
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x15, x12, ror #17
        eor x30, x2, x30, ror #22
        bic x2, x16, x15, ror #7
        eor x12, x2, x12, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x17, x16, ror #38
        eor x15, x2, x15, ror #45
        bic x2, x8, x17, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x16, x2, x16, ror #35
        bic x2, x19, x8, ror #5
        eor x17, x2, x17, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x3
        mov x8, x7
        bic x2, x6, x7, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x3, x3, x2
        bic x2, x22, x6, ror #62
        eor x7, x2, x7, ror #8
        ldr d31, [x1, #-72]
        bic x2, x4, x22, ror #4
        eor x6, x2, x6, ror #2
        bic x2, x19, x4, ror #62
        dup v31.2d, v31.d[0]
        eor x22, x2, x22, ror #2
        bic x2, x8, x19, ror #54
        eor x4, x2, x4, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x8, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x8
        eor x8, x24, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x8, x8, x13
        eor x8, x8, x30, ror #14
        eor x8, x8, x3, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x28, x23, ror #39
        eor x2, x2, x9, ror #51
        eor x2, x2, x12, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x7, ror #22
        str x3, [sp, #104]
        eor x3, x5, x26, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x3, x3, x10, ror #24
        eor x3, x3, x15, ror #8
        eor x3, x3, x6, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x24, [sp, #80]
        eor x24, x11, x27, ror #44
        eor x24, x24, x21, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x24, x24, x16, ror #13
        eor x24, x24, x22, ror #1
        str x30, [sp, #96]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x30, x4, x25, ror #10
        eor x30, x30, x20, ror #9
        eor x30, x30, x14, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x30, x30, x17, ror #61
        str x13, [sp, #88]
        eor x13, x3, x8, ror #40
        eor x28, x13, x28, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x23, x13, x23, ror #19
        eor x9, x13, x9, ror #31
        eor x12, x13, x12, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x7, x13, x7, ror #2
        eor x13, x24, x2, ror #46
        eor x26, x13, x26, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x5, x13, x5, ror #3
        eor x10, x13, x10, ror #27
        eor x15, x13, x15, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x6, x13, x6
        eor x13, x2, x30, ror #31
        eor x2, x3, x30, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x27, x2, x27, ror #42
        eor x21, x2, x21, ror #36
        eor x11, x2, x11, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x16, x2, x16, ror #11
        eor x22, x2, x22, ror #63
        eor x3, x8, x24, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x25, x3, x25, ror #45
        eor x20, x3, x20, ror #44
        eor x14, x3, x14, ror #17
        eor x17, x3, x17, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x4, x3, x4, ror #35
        eor x19, x13, x19
        ldr x30, [sp, #80]
        mov v25.16b, v1.16b
        eor x30, x13, x30, ror #61
        ldr x3, [sp, #88]
        eor x3, x13, x3, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x24, [sp, #96]
        eor x24, x13, x24, ror #11
        ldr x8, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x8, x13, x8, ror #21
        mov x13, x19
        mov x2, x23
        xar v9.2d, v22.2d, v31.2d, #3
        str x28, [sp, #104]
        bic x28, x10, x23, ror #1
        eor x19, x19, x28, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x28, x16, x10, ror #39
        eor x23, x28, x23, ror #40
        bic x28, x4, x16, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x10, x28, x10, ror #58
        bic x28, x13, x4, ror #46
        eor x16, x28, x16, ror #1
        bic x28, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x4, x28, x4, ror #5
        mov x2, x27
        mov x13, x20
        xar v2.2d, v12.2d, v31.2d, #21
        bic x28, x3, x20, ror #43
        eor x27, x28, x27, ror #61
        bic x28, x12, x3, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x20, x20, x28
        bic x28, x6, x12, ror #18
        eor x3, x28, x3, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x28, x2, x6, ror #28
        eor x12, x28, x12, ror #46
        bic x28, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x6, x28, x6, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x28, x5
        str x19, [sp, #104]
        bic x19, x11, x5, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x17, x11, ror #9
        eor x5, x19, x5, ror #25
        bic x19, x8, x17, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x11, x19, x11, ror #15
        bic x19, x2, x8, ror #26
        eor x17, x19, x17, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x28, x2, ror #7
        eor x8, x19, x8, ror #33
        mov x28, x25
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x30
        bic x19, x9, x30, ror #17
        eor x25, x19, x25, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x15, x9, ror #7
        eor x30, x19, x30, ror #24
        bic x19, x22, x15, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x9, x19, x9, ror #45
        bic x19, x28, x22, ror #61
        eor x15, x19, x15, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x28, ror #5
        eor x22, x19, x22, ror #2
        mov x2, x26
        xar v3.2d, v18.2d, v27.2d, #43
        mov x28, x21
        bic x19, x14, x21, ror #10
        eor x26, x26, x19
        bic x19, x24, x14, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x21, x19, x21, ror #8
        bic x19, x7, x24, ror #4
        eor x14, x19, x14, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x7, ror #62
        eor x24, x19, x24, ror #2
        bic x19, x28, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x7, x19, x7, ror #52
        ldr x28, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x28
        eor x28, x27, x2, ror #3
        eor x28, x28, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x28, x28, x25, ror #14
        eor x28, x28, x26, ror #24
        eor x19, x23, x20, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x5, ror #51
        eor x19, x19, x30, ror #3
        eor x19, x19, x21, ror #22
        mov v30.16b, v1.16b
        str x26, [sp, #104]
        eor x26, x3, x10, ror #24
        eor x26, x26, x11, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x26, x26, x9, ror #8
        eor x26, x26, x14, ror #61
        str x27, [sp, #96]
        eor x27, x17, x16, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x27, x27, x12, ror #38
        eor x27, x27, x15, ror #13
        eor x27, x27, x24, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x25, [sp, #88]
        eor x25, x7, x4, ror #10
        eor x25, x25, x6, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x25, x25, x8, ror #46
        eor x25, x25, x22, ror #61
        str x13, [sp, #80]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x26, x28, ror #40
        eor x23, x13, x23, ror #44
        eor x20, x13, x20, ror #19
        mov v29.16b, v5.16b
        eor x5, x13, x5, ror #31
        eor x30, x13, x30, ror #47
        eor x21, x13, x21, ror #2
        mov v30.16b, v6.16b
        eor x13, x27, x19, ror #46
        eor x10, x13, x10, ror #27
        eor x3, x13, x3, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x11, x13, x11, ror #27
        eor x9, x13, x9, ror #11
        eor x14, x13, x14
        eor x13, x19, x25, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x26, x25, ror #8
        eor x16, x19, x16, ror #42
        eor x12, x19, x12, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x17, x19, x17, ror #62
        eor x15, x19, x15, ror #11
        eor x24, x19, x24, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x26, x28, x27, ror #24
        eor x4, x26, x4, ror #45
        eor x6, x26, x6, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x8, x26, x8, ror #17
        eor x22, x26, x22, ror #32
        eor x7, x26, x7, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x25, [sp, #96]
        eor x25, x13, x25, ror #61
        mov v30.16b, v11.16b
        ldr x26, [sp, #80]
        eor x26, x13, x26, ror #61
        ldr x27, [sp, #88]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x27, x13, x27, ror #11
        ldr x28, [sp, #104]
        eor x28, x13, x28, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x20
        str x23, [sp, #104]
        bic x23, x11, x20, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x23, ror #40
        bic x23, x15, x11, ror #39
        eor x20, x23, x20, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x23, x7, x15, ror #19
        eor x11, x23, x11, ror #58
        bic x23, x13, x7, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x15, x23, x15, ror #1
        bic x23, x19, x13, ror #23
        eor x7, x23, x7, ror #5
        mov v29.16b, v15.16b
        mov x19, x16
        mov x13, x6
        bic x23, x26, x6, ror #43
        mov v30.16b, v16.16b
        eor x16, x23, x16, ror #61
        bic x23, x30, x26, ror #21
        eor x6, x6, x23
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x23, x14, x30, ror #18
        eor x26, x23, x26, ror #39
        bic x23, x19, x14, ror #28
        eor x30, x23, x30, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x23, x13, x19, ror #18
        eor x14, x23, x14, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x23, x3
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x17, x3, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x22, x17, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x3, x2, x3, ror #25
        bic x2, x28, x22, ror #6
        eor x17, x2, x17, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x28, ror #26
        eor x22, x2, x22, ror #32
        bic x2, x23, x19, ror #7
        mov v30.16b, v21.16b
        eor x28, x2, x28, ror #33
        mov x23, x4
        mov x19, x25
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x5, x25, ror #17
        eor x4, x2, x4, ror #22
        bic x2, x9, x5, ror #7
        eor x25, x2, x25, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x24, x9, ror #38
        eor x5, x2, x5, ror #45
        bic x2, x23, x24, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x9, x2, x9, ror #35
        bic x2, x19, x23, ror #5
        eor x24, x2, x24, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x10
        mov x23, x12
        bic x2, x8, x12, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x10, x10, x2
        bic x2, x27, x8, ror #62
        eor x12, x2, x12, ror #8
        ldr d31, [x1, #-80]
        bic x2, x21, x27, ror #4
        eor x8, x2, x8, ror #2
        bic x2, x19, x21, ror #62
        dup v31.2d, v31.d[0]
        eor x27, x2, x27, ror #2
        bic x2, x23, x19, ror #54
        eor x21, x2, x21, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x23, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x23
        eor x23, x16, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x23, x23, x13
        eor x23, x23, x4, ror #14
        eor x23, x23, x10, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x20, x6, ror #39
        eor x2, x2, x3, ror #51
        eor x2, x2, x25, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x12, ror #22
        str x10, [sp, #104]
        eor x10, x26, x11, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x10, x10, x17, ror #24
        eor x10, x10, x5, ror #8
        eor x10, x10, x8, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x16, [sp, #88]
        eor x16, x22, x15, ror #44
        eor x16, x16, x30, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x16, x16, x9, ror #13
        eor x16, x16, x27, ror #1
        str x4, [sp, #80]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x4, x21, x7, ror #10
        eor x4, x4, x14, ror #9
        eor x4, x4, x28, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x4, x4, x24, ror #61
        str x13, [sp, #96]
        eor x13, x10, x23, ror #40
        eor x20, x13, x20, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x6, x13, x6, ror #19
        eor x3, x13, x3, ror #31
        eor x25, x13, x25, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x12, x13, x12, ror #2
        eor x13, x16, x2, ror #46
        eor x11, x13, x11, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x26, x13, x26, ror #3
        eor x17, x13, x17, ror #27
        eor x5, x13, x5, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x8, x13, x8
        eor x13, x2, x4, ror #31
        eor x2, x10, x4, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x15, x2, x15, ror #42
        eor x30, x2, x30, ror #36
        eor x22, x2, x22, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x9, x2, x9, ror #11
        eor x27, x2, x27, ror #63
        eor x10, x23, x16, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x7, x10, x7, ror #45
        eor x14, x10, x14, ror #44
        eor x28, x10, x28, ror #17
        eor x24, x10, x24, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x21, x10, x21, ror #35
        eor x19, x13, x19
        ldr x4, [sp, #88]
        mov v25.16b, v1.16b
        eor x4, x13, x4, ror #61
        ldr x10, [sp, #96]
        eor x10, x13, x10, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x16, [sp, #80]
        eor x16, x13, x16, ror #11
        ldr x23, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x23, x13, x23, ror #21
        mov x13, x19
        mov x2, x6
        xar v9.2d, v22.2d, v31.2d, #3
        str x20, [sp, #104]
        bic x20, x17, x6, ror #1
        eor x19, x19, x20, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x20, x9, x17, ror #39
        eor x6, x20, x6, ror #40
        bic x20, x21, x9, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x17, x20, x17, ror #58
        bic x20, x13, x21, ror #46
        eor x9, x20, x9, ror #1
        bic x20, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x21, x20, x21, ror #5
        mov x2, x15
        mov x13, x14
        xar v2.2d, v12.2d, v31.2d, #21
        bic x20, x10, x14, ror #43
        eor x15, x20, x15, ror #61
        bic x20, x25, x10, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x14, x14, x20
        bic x20, x8, x25, ror #18
        eor x10, x20, x10, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x20, x2, x8, ror #28
        eor x25, x20, x25, ror #46
        bic x20, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x8, x20, x8, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x20, x26
        str x19, [sp, #104]
        bic x19, x22, x26, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x24, x22, ror #9
        eor x26, x19, x26, ror #25
        bic x19, x23, x24, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x22, x19, x22, ror #15
        bic x19, x2, x23, ror #26
        eor x24, x19, x24, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x20, x2, ror #7
        eor x23, x19, x23, ror #33
        mov x20, x7
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x4
        bic x19, x3, x4, ror #17
        eor x7, x19, x7, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x5, x3, ror #7
        eor x4, x19, x4, ror #24
        bic x19, x27, x5, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x3, x19, x3, ror #45
        bic x19, x20, x27, ror #61
        eor x5, x19, x5, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x20, ror #5
        eor x27, x19, x27, ror #2
        mov x2, x11
        xar v3.2d, v18.2d, v27.2d, #43
        mov x20, x30
        bic x19, x28, x30, ror #10
        eor x11, x11, x19
        bic x19, x16, x28, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x30, x19, x30, ror #8
        bic x19, x12, x16, ror #4
        eor x28, x19, x28, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x12, ror #62
        eor x16, x19, x16, ror #2
        bic x19, x20, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x12, x19, x12, ror #52
        ldr x20, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x20
        eor x20, x15, x2, ror #3
        eor x20, x20, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x20, x20, x7, ror #14
        eor x20, x20, x11, ror #24
        eor x19, x6, x14, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x26, ror #51
        eor x19, x19, x4, ror #3
        eor x19, x19, x30, ror #22
        mov v30.16b, v1.16b
        str x11, [sp, #104]
        eor x11, x10, x17, ror #24
        eor x11, x11, x22, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x11, x11, x3, ror #8
        eor x11, x11, x28, ror #61
        str x15, [sp, #80]
        eor x15, x24, x9, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x15, x15, x25, ror #38
        eor x15, x15, x5, ror #13
        eor x15, x15, x16, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x7, [sp, #96]
        eor x7, x12, x21, ror #10
        eor x7, x7, x8, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x7, x7, x23, ror #46
        eor x7, x7, x27, ror #61
        str x13, [sp, #88]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x11, x20, ror #40
        eor x6, x13, x6, ror #44
        eor x14, x13, x14, ror #19
        mov v29.16b, v5.16b
        eor x26, x13, x26, ror #31
        eor x4, x13, x4, ror #47
        eor x30, x13, x30, ror #2
        mov v30.16b, v6.16b
        eor x13, x15, x19, ror #46
        eor x17, x13, x17, ror #27
        eor x10, x13, x10, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x22, x13, x22, ror #27
        eor x3, x13, x3, ror #11
        eor x28, x13, x28
        eor x13, x19, x7, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x11, x7, ror #8
        eor x9, x19, x9, ror #42
        eor x25, x19, x25, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x24, x19, x24, ror #62
        eor x5, x19, x5, ror #11
        eor x16, x19, x16, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x11, x20, x15, ror #24
        eor x21, x11, x21, ror #45
        eor x8, x11, x8, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x23, x11, x23, ror #17
        eor x27, x11, x27, ror #32
        eor x12, x11, x12, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x7, [sp, #80]
        eor x7, x13, x7, ror #61
        mov v30.16b, v11.16b
        ldr x11, [sp, #88]
        eor x11, x13, x11, ror #61
        ldr x15, [sp, #96]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x15, x13, x15, ror #11
        ldr x20, [sp, #104]
        eor x20, x13, x20, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x14
        str x6, [sp, #104]
        bic x6, x22, x14, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x6, ror #40
        bic x6, x5, x22, ror #39
        eor x14, x6, x14, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x6, x12, x5, ror #19
        eor x22, x6, x22, ror #58
        bic x6, x13, x12, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x5, x6, x5, ror #1
        bic x6, x19, x13, ror #23
        eor x12, x6, x12, ror #5
        mov v29.16b, v15.16b
        mov x19, x9
        mov x13, x8
        bic x6, x11, x8, ror #43
        mov v30.16b, v16.16b
        eor x9, x6, x9, ror #61
        bic x6, x4, x11, ror #21
        eor x8, x8, x6
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x6, x28, x4, ror #18
        eor x11, x6, x11, ror #39
        bic x6, x19, x28, ror #28
        eor x4, x6, x4, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x6, x13, x19, ror #18
        eor x28, x6, x28, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x6, x10
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x24, x10, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x27, x24, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x10, x2, x10, ror #25
        bic x2, x20, x27, ror #6
        eor x24, x2, x24, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x20, ror #26
        eor x27, x2, x27, ror #32
        bic x2, x6, x19, ror #7
        mov v30.16b, v21.16b
        eor x20, x2, x20, ror #33
        mov x6, x21
        mov x19, x7
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x26, x7, ror #17
        eor x21, x2, x21, ror #22
        bic x2, x3, x26, ror #7
        eor x7, x2, x7, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x16, x3, ror #38
        eor x26, x2, x26, ror #45
        bic x2, x6, x16, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x3, x2, x3, ror #35
        bic x2, x19, x6, ror #5
        eor x16, x2, x16, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x17
        mov x6, x25
        bic x2, x23, x25, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x17, x17, x2
        bic x2, x15, x23, ror #62
        eor x25, x2, x25, ror #8
        ldr d31, [x1, #-88]
        bic x2, x30, x15, ror #4
        eor x23, x2, x23, ror #2
        bic x2, x19, x30, ror #62
        dup v31.2d, v31.d[0]
        eor x15, x2, x15, ror #2
        bic x2, x6, x19, ror #54
        eor x30, x2, x30, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x6, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x6
        eor x6, x9, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x6, x6, x13
        eor x6, x6, x21, ror #14
        eor x6, x6, x17, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x14, x8, ror #39
        eor x2, x2, x10, ror #51
        eor x2, x2, x7, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x25, ror #22
        str x17, [sp, #104]
        eor x17, x11, x22, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x17, x17, x24, ror #24
        eor x17, x17, x26, ror #8
        eor x17, x17, x23, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x9, [sp, #96]
        eor x9, x27, x5, ror #44
        eor x9, x9, x4, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x9, x9, x3, ror #13
        eor x9, x9, x15, ror #1
        str x21, [sp, #88]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x21, x30, x12, ror #10
        eor x21, x21, x28, ror #9
        eor x21, x21, x20, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x21, x21, x16, ror #61
        str x13, [sp, #80]
        eor x13, x17, x6, ror #40
        eor x14, x13, x14, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x8, x13, x8, ror #19
        eor x10, x13, x10, ror #31
        eor x7, x13, x7, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x25, x13, x25, ror #2
        eor x13, x9, x2, ror #46
        eor x22, x13, x22, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x11, x13, x11, ror #3
        eor x24, x13, x24, ror #27
        eor x26, x13, x26, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x23, x13, x23
        eor x13, x2, x21, ror #31
        eor x2, x17, x21, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x5, x2, x5, ror #42
        eor x4, x2, x4, ror #36
        eor x27, x2, x27, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x3, x2, x3, ror #11
        eor x15, x2, x15, ror #63
        eor x17, x6, x9, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x12, x17, x12, ror #45
        eor x28, x17, x28, ror #44
        eor x20, x17, x20, ror #17
        eor x16, x17, x16, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x30, x17, x30, ror #35
        eor x19, x13, x19
        ldr x21, [sp, #96]
        mov v25.16b, v1.16b
        eor x21, x13, x21, ror #61
        ldr x17, [sp, #80]
        eor x17, x13, x17, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x9, [sp, #88]
        eor x9, x13, x9, ror #11
        ldr x6, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x6, x13, x6, ror #21
        mov x13, x19
        mov x2, x8
        xar v9.2d, v22.2d, v31.2d, #3
        str x14, [sp, #104]
        bic x14, x24, x8, ror #1
        eor x19, x19, x14, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x14, x3, x24, ror #39
        eor x8, x14, x8, ror #40
        bic x14, x30, x3, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x24, x14, x24, ror #58
        bic x14, x13, x30, ror #46
        eor x3, x14, x3, ror #1
        bic x14, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x30, x14, x30, ror #5
        mov x2, x5
        mov x13, x28
        xar v2.2d, v12.2d, v31.2d, #21
        bic x14, x17, x28, ror #43
        eor x5, x14, x5, ror #61
        bic x14, x7, x17, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x28, x28, x14
        bic x14, x23, x7, ror #18
        eor x17, x14, x17, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x14, x2, x23, ror #28
        eor x7, x14, x7, ror #46
        bic x14, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x23, x14, x23, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x14, x11
        str x19, [sp, #104]
        bic x19, x27, x11, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x16, x27, ror #9
        eor x11, x19, x11, ror #25
        bic x19, x6, x16, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x27, x19, x27, ror #15
        bic x19, x2, x6, ror #26
        eor x16, x19, x16, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x14, x2, ror #7
        eor x6, x19, x6, ror #33
        mov x14, x12
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x21
        bic x19, x10, x21, ror #17
        eor x12, x19, x12, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x26, x10, ror #7
        eor x21, x19, x21, ror #24
        bic x19, x15, x26, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x10, x19, x10, ror #45
        bic x19, x14, x15, ror #61
        eor x26, x19, x26, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x14, ror #5
        eor x15, x19, x15, ror #2
        mov x2, x22
        xar v3.2d, v18.2d, v27.2d, #43
        mov x14, x4
        bic x19, x20, x4, ror #10
        eor x22, x22, x19
        bic x19, x9, x20, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x4, x19, x4, ror #8
        bic x19, x25, x9, ror #4
        eor x20, x19, x20, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x25, ror #62
        eor x9, x19, x9, ror #2
        bic x19, x14, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x25, x19, x25, ror #52
        ldr x14, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x14
        eor x14, x5, x2, ror #3
        eor x14, x14, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x14, x14, x12, ror #14
        eor x14, x14, x22, ror #24
        eor x19, x8, x28, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x11, ror #51
        eor x19, x19, x21, ror #3
        eor x19, x19, x4, ror #22
        mov v30.16b, v1.16b
        str x22, [sp, #104]
        eor x22, x17, x24, ror #24
        eor x22, x22, x27, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x22, x22, x10, ror #8
        eor x22, x22, x20, ror #61
        str x5, [sp, #88]
        eor x5, x16, x3, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x5, x5, x7, ror #38
        eor x5, x5, x26, ror #13
        eor x5, x5, x9, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x12, [sp, #80]
        eor x12, x25, x30, ror #10
        eor x12, x12, x23, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x12, x12, x6, ror #46
        eor x12, x12, x15, ror #61
        str x13, [sp, #96]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x22, x14, ror #40
        eor x8, x13, x8, ror #44
        eor x28, x13, x28, ror #19
        mov v29.16b, v5.16b
        eor x11, x13, x11, ror #31
        eor x21, x13, x21, ror #47
        eor x4, x13, x4, ror #2
        mov v30.16b, v6.16b
        eor x13, x5, x19, ror #46
        eor x24, x13, x24, ror #27
        eor x17, x13, x17, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x27, x13, x27, ror #27
        eor x10, x13, x10, ror #11
        eor x20, x13, x20
        eor x13, x19, x12, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x22, x12, ror #8
        eor x3, x19, x3, ror #42
        eor x7, x19, x7, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x16, x19, x16, ror #62
        eor x26, x19, x26, ror #11
        eor x9, x19, x9, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x22, x14, x5, ror #24
        eor x30, x22, x30, ror #45
        eor x23, x22, x23, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x6, x22, x6, ror #17
        eor x15, x22, x15, ror #32
        eor x25, x22, x25, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x12, [sp, #88]
        eor x12, x13, x12, ror #61
        mov v30.16b, v11.16b
        ldr x22, [sp, #96]
        eor x22, x13, x22, ror #61
        ldr x5, [sp, #80]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x5, x13, x5, ror #11
        ldr x14, [sp, #104]
        eor x14, x13, x14, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x28
        str x8, [sp, #104]
        bic x8, x27, x28, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x8, ror #40
        bic x8, x26, x27, ror #39
        eor x28, x8, x28, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x8, x25, x26, ror #19
        eor x27, x8, x27, ror #58
        bic x8, x13, x25, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x26, x8, x26, ror #1
        bic x8, x19, x13, ror #23
        eor x25, x8, x25, ror #5
        mov v29.16b, v15.16b
        mov x19, x3
        mov x13, x23
        bic x8, x22, x23, ror #43
        mov v30.16b, v16.16b
        eor x3, x8, x3, ror #61
        bic x8, x21, x22, ror #21
        eor x23, x23, x8
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x8, x20, x21, ror #18
        eor x22, x8, x22, ror #39
        bic x8, x19, x20, ror #28
        eor x21, x8, x21, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x8, x13, x19, ror #18
        eor x20, x8, x20, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x8, x17
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x16, x17, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x15, x16, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x17, x2, x17, ror #25
        bic x2, x14, x15, ror #6
        eor x16, x2, x16, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x14, ror #26
        eor x15, x2, x15, ror #32
        bic x2, x8, x19, ror #7
        mov v30.16b, v21.16b
        eor x14, x2, x14, ror #33
        mov x8, x30
        mov x19, x12
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x11, x12, ror #17
        eor x30, x2, x30, ror #22
        bic x2, x10, x11, ror #7
        eor x12, x2, x12, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x9, x10, ror #38
        eor x11, x2, x11, ror #45
        bic x2, x8, x9, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x10, x2, x10, ror #35
        bic x2, x19, x8, ror #5
        eor x9, x2, x9, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x24
        mov x8, x7
        bic x2, x6, x7, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x24, x24, x2
        bic x2, x5, x6, ror #62
        eor x7, x2, x7, ror #8
        ldr d31, [x1, #-96]
        bic x2, x4, x5, ror #4
        eor x6, x2, x6, ror #2
        bic x2, x19, x4, ror #62
        dup v31.2d, v31.d[0]
        eor x5, x2, x5, ror #2
        bic x2, x8, x19, ror #54
        eor x4, x2, x4, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x8, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x8
        str x19, [x0, #400]
        ror x28, x28, #1
        str x28, [x0, #408]
        ror x27, x27, #46
        str x27, [x0, #416]
        str x26, [x0, #424]
        ror x25, x25, #41
        str x25, [x0, #432]
        ror x3, x3, #61
        str x3, [x0, #440]
        ror x23, x23, #40
        str x23, [x0, #448]
        ror x22, x22, #22
        str x22, [x0, #456]
        ror x21, x21, #58
        str x21, [x0, #464]
        ror x20, x20, #40
        str x20, [x0, #472]
        ror x13, x13, #61
        str x13, [x0, #480]
        ror x17, x17, #52
        str x17, [x0, #488]
        ror x16, x16, #46
        str x16, [x0, #496]
        ror x15, x15, #20
        str x15, [x0, #504]
        ror x14, x14, #13
        str x14, [x0, #512]
        ror x30, x30, #11
        str x30, [x0, #520]
        ror x12, x12, #4
        str x12, [x0, #528]
        ror x11, x11, #30
        str x11, [x0, #536]
        ror x10, x10, #33
        str x10, [x0, #544]
        ror x9, x9, #28
        str x9, [x0, #552]
        ror x24, x24, #21
        str x24, [x0, #560]
        ror x7, x7, #23
        str x7, [x0, #568]
        ror x6, x6, #19
        str x6, [x0, #576]
        ror x5, x5, #21
        str x5, [x0, #584]
        ror x4, x4, #31
        str x4, [x0, #592]
        sub x1, x1, #192
        ldr x30, [x0, #600]
        ldr x28, [x0, #608]
        ldr x27, [x0, #616]
        ldr x26, [x0, #624]
        ldr x25, [x0, #632]
        ldr x24, [x0, #640]
        ldr x23, [x0, #648]
        ldr x22, [x0, #656]
        ldr x21, [x0, #664]
        ldr x20, [x0, #672]
        ldr x19, [x0, #680]
        ldr x17, [x0, #688]
        ldr x16, [x0, #696]
        ldr x15, [x0, #704]
        ldr x14, [x0, #712]
        ldr x13, [x0, #720]
        ldr x12, [x0, #728]
        ldr x11, [x0, #736]
        ldr x10, [x0, #744]
        ldr x9, [x0, #752]
        ldr x8, [x0, #760]
        ldr x7, [x0, #768]
        ldr x6, [x0, #776]
        ldr x5, [x0, #784]
        ldr x4, [x0, #792]
        eor x3, x30, x24
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x3, x3, x19
        eor x3, x3, x13
        eor x3, x3, x8
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x28, x23
        eor x2, x2, x17
        eor x2, x2, x12
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x7
        str x30, [sp, #80]
        eor x30, x27, x22
        eor x30, x30, x16
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x30, x30, x11
        eor x30, x30, x6
        str x24, [sp, #88]
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        eor x24, x26, x21
        eor x24, x24, x15
        eor x24, x24, x10
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x24, x24, x5
        str x19, [sp, #96]
        eor x19, x25, x20
        eor x19, x19, x14
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x19, x19, x9
        eor x19, x19, x4
        str x13, [sp, #104]
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x13, x3, x30, ror #63
        eor x28, x13, x28
        eor x23, x13, x23
        eor x17, x13, x17
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x12, x13, x12
        eor x7, x13, x7
        eor x13, x2, x24, ror #63
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x27, x13, x27
        eor x22, x13, x22
        eor x16, x13, x16
        rax1 v30.2d, v29.2d, v26.2d
        eor x11, x13, x11
        eor x6, x13, x6
        eor x13, x19, x2, ror #63
        eor x2, x30, x19, ror #63
        rax1 v31.2d, v26.2d, v28.2d
        eor x26, x2, x26
        eor x21, x2, x21
        eor x15, x2, x15
        rax1 v26.2d, v25.2d, v27.2d
        eor x10, x2, x10
        eor x5, x2, x5
        eor x30, x24, x3, ror #63
        rax1 v27.2d, v27.2d, v29.2d
        eor x25, x30, x25
        eor x20, x30, x20
        eor x14, x30, x14
        eor x9, x30, x9
        rax1 v28.2d, v28.2d, v25.2d
        eor x4, x30, x4
        ldr x19, [sp, #80]
        eor x19, x13, x19
        eor v0.16b, v0.16b, v30.16b
        ldr x30, [sp, #88]
        eor x30, x13, x30
        ldr x24, [sp, #96]
        eor x24, x13, x24
        mov v25.16b, v1.16b
        ldr x3, [sp, #104]
        eor x3, x13, x3
        eor x8, x13, x8
        xar v1.2d, v6.2d, v26.2d, #20
        mov x13, x19
        mov x2, x23
        str x28, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        bic x28, x16, x23, ror #63
        eor x19, x19, x28, ror #21
        bic x28, x10, x16, ror #42
        eor x23, x23, x28, ror #23
        xar v9.2d, v22.2d, v31.2d, #3
        ror x23, x23, #19
        bic x28, x4, x10, ror #57
        eor x16, x16, x28, ror #29
        xar v22.2d, v14.2d, v28.2d, #25
        ror x16, x16, #39
        bic x28, x13, x4, ror #50
        eor x10, x28, x10, ror #43
        xar v14.2d, v20.2d, v30.2d, #46
        bic x28, x2, x13, ror #44
        eor x4, x4, x28, ror #34
        ror x4, x4, #9
        mov x2, x26
        xar v20.2d, v2.2d, v31.2d, #2
        mov x13, x20
        bic x28, x24, x20, ror #47
        eor x26, x28, x26, ror #39
        xar v2.2d, v12.2d, v31.2d, #21
        bic x28, x12, x24, ror #42
        eor x20, x20, x28, ror #39
        ror x20, x20, #4
        bic x28, x6, x12, ror #16
        xar v12.2d, v13.2d, v27.2d, #39
        eor x24, x24, x28, ror #6
        ror x24, x24, #39
        bic x28, x2, x6, ror #31
        xar v13.2d, v19.2d, v28.2d, #56
        eor x12, x12, x28, ror #17
        ror x12, x12, #25
        bic x28, x13, x2, ror #56
        xar v19.2d, v23.2d, v27.2d, #8
        eor x6, x6, x28, ror #41
        ror x6, x6, #27
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x28, x22
        str x19, [sp, #104]
        bic x19, x15, x22, ror #19
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x13, x19, ror #40
        ror x13, x13, #2
        bic x19, x9, x15, ror #47
        eor x22, x22, x19, ror #62
        xar v4.2d, v24.2d, v28.2d, #50
        ror x22, x22, #6
        bic x19, x8, x9, ror #10
        eor x15, x19, x15, ror #57
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x2, x8, ror #47
        eor x9, x9, x19, ror #7
        ror x9, x9, #36
        xar v21.2d, v8.2d, v27.2d, #9
        bic x19, x28, x2, ror #5
        eor x8, x8, x19, ror #12
        ror x8, x8, #33
        mov x28, x25
        xar v8.2d, v16.2d, v26.2d, #19
        mov x2, x30
        bic x19, x17, x30, ror #38
        eor x25, x25, x19, ror #17
        xar v16.2d, v5.2d, v30.2d, #28
        ror x25, x25, #26
        bic x19, x11, x17, ror #5
        eor x30, x30, x19, ror #21
        xar v5.2d, v3.2d, v27.2d, #36
        ror x30, x30, #24
        bic x19, x5, x11, ror #41
        eor x17, x17, x19, ror #18
        ror x17, x17, #24
        xar v3.2d, v18.2d, v27.2d, #43
        bic x19, x28, x5, ror #35
        eor x11, x11, x19, ror #52
        ror x11, x11, #16
        xar v18.2d, v17.2d, v31.2d, #49
        bic x19, x2, x28, ror #9
        eor x5, x19, x5, ror #44
        mov x2, x27
        mov x28, x21
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x14, x21, ror #48
        eor x27, x27, x19, ror #23
        ror x27, x27, #45
        xar v11.2d, v7.2d, v31.2d, #58
        bic x19, x3, x14, ror #2
        eor x21, x19, x21, ror #50
        bic x19, x7, x3, ror #25
        xar v7.2d, v10.2d, v30.2d, #61
        eor x14, x14, x19, ror #37
        ror x14, x14, #6
        bic x19, x2, x7, ror #60
        eor x3, x3, x19, ror #43
        xar v10.2d, v25.2d, v26.2d, #63
        ror x3, x3, #2
        bic x19, x28, x2, ror #57
        eor x7, x7, x19, ror #11
        mov v29.16b, v0.16b
        ror x7, x7, #31
        ldr x28, [x1], #8
        ldr x2, [sp, #104]
        mov v30.16b, v1.16b
        eor x2, x2, x28
        eor x28, x26, x2, ror #3
        eor x28, x28, x13
        eor x28, x28, x25, ror #14
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x28, x28, x27, ror #24
        eor x19, x23, x20, ror #39
        eor x19, x19, x22, ror #51
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x19, x19, x30, ror #3
        eor x19, x19, x21, ror #22
        str x27, [sp, #104]
        eor x27, x24, x16, ror #24
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        eor x27, x27, x15, ror #24
        eor x27, x27, x17, ror #8
        eor x27, x27, x14, ror #61
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        str x26, [sp, #96]
        eor x26, x9, x10, ror #44
        eor x26, x26, x12, ror #38
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x26, x26, x11, ror #13
        eor x26, x26, x3, ror #1
        str x25, [sp, #88]
        eor x25, x7, x4, ror #10
        mov v29.16b, v5.16b
        eor x25, x25, x6, ror #9
        eor x25, x25, x8, ror #46
        eor x25, x25, x5, ror #61
        mov v30.16b, v6.16b
        str x13, [sp, #80]
        eor x13, x27, x28, ror #40
        eor x23, x13, x23, ror #44
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x20, x13, x20, ror #19
        eor x22, x13, x22, ror #31
        eor x30, x13, x30, ror #47
        eor x21, x13, x21, ror #2
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x13, x26, x19, ror #46
        eor x16, x13, x16, ror #27
        eor x24, x13, x24, ror #3
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x15, x13, x15, ror #27
        eor x17, x13, x17, ror #11
        eor x14, x13, x14
        eor x13, x19, x25, ror #31
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x19, x27, x25, ror #8
        eor x10, x19, x10, ror #42
        eor x12, x19, x12, ror #36
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x9, x19, x9, ror #62
        eor x11, x19, x11, ror #11
        eor x3, x19, x3, ror #63
        mov v29.16b, v10.16b
        eor x27, x28, x26, ror #24
        eor x4, x27, x4, ror #45
        eor x6, x27, x6, ror #44
        eor x8, x27, x8, ror #17
        mov v30.16b, v11.16b
        eor x5, x27, x5, ror #32
        eor x7, x27, x7, ror #35
        eor x2, x13, x2
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        ldr x25, [sp, #96]
        eor x25, x13, x25, ror #61
        ldr x27, [sp, #80]
        eor x27, x13, x27, ror #61
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        ldr x26, [sp, #88]
        eor x26, x13, x26, ror #11
        ldr x28, [sp, #104]
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x28, x13, x28, ror #21
        mov x13, x2
        mov x19, x20
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        str x23, [sp, #104]
        bic x23, x15, x20, ror #1
        eor x2, x2, x23, ror #40
        bic x23, x11, x15, ror #39
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x20, x23, x20, ror #40
        bic x23, x7, x11, ror #19
        eor x15, x23, x15, ror #58
        mov v29.16b, v15.16b
        bic x23, x13, x7, ror #46
        eor x11, x23, x11, ror #1
        bic x23, x19, x13, ror #23
        mov v30.16b, v16.16b
        eor x7, x23, x7, ror #5
        mov x19, x10
        mov x13, x6
        bic x23, x27, x6, ror #43
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        eor x10, x23, x10, ror #61
        bic x23, x30, x27, ror #21
        eor x6, x6, x23
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x23, x14, x30, ror #18
        eor x27, x23, x27, ror #39
        bic x23, x19, x14, ror #28
        eor x30, x23, x30, ror #46
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        bic x23, x13, x19, ror #18
        eor x14, x23, x14, ror #46
        ldr x13, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        mov x19, x13
        mov x23, x24
        str x2, [sp, #104]
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        bic x2, x9, x24, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x5, x9, ror #9
        eor x24, x2, x24, ror #25
        mov v29.16b, v20.16b
        bic x2, x28, x5, ror #6
        eor x9, x2, x9, ror #15
        bic x2, x19, x28, ror #26
        mov v30.16b, v21.16b
        eor x5, x2, x5, ror #32
        bic x2, x23, x19, ror #7
        eor x28, x2, x28, ror #33
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        mov x23, x4
        mov x19, x25
        bic x2, x22, x25, ror #17
        eor x4, x2, x4, ror #22
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x17, x22, ror #7
        eor x25, x2, x25, ror #24
        bic x2, x3, x17, ror #38
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x22, x2, x22, ror #45
        bic x2, x23, x3, ror #61
        eor x17, x2, x17, ror #35
        bic x2, x19, x23, ror #5
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        eor x3, x2, x3, ror #2
        mov x19, x16
        mov x23, x12
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        bic x2, x8, x12, ror #10
        eor x16, x16, x2
        bic x2, x26, x8, ror #62
        ldr d31, [x1, #88]
        eor x12, x2, x12, ror #8
        bic x2, x21, x26, ror #4
        eor x8, x2, x8, ror #2
        bic x2, x19, x21, ror #62
        dup v31.2d, v31.d[0]
        eor x26, x2, x26, ror #2
        bic x2, x23, x19, ror #54
        eor x21, x2, x21, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x23, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x23
        eor x23, x10, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x23, x23, x13
        eor x23, x23, x4, ror #14
        eor x23, x23, x16, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x20, x6, ror #39
        eor x2, x2, x24, ror #51
        eor x2, x2, x25, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x12, ror #22
        str x16, [sp, #104]
        eor x16, x27, x15, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x16, x16, x9, ror #24
        eor x16, x16, x22, ror #8
        eor x16, x16, x8, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x10, [sp, #88]
        eor x10, x5, x11, ror #44
        eor x10, x10, x30, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x10, x10, x17, ror #13
        eor x10, x10, x26, ror #1
        str x4, [sp, #80]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x4, x21, x7, ror #10
        eor x4, x4, x14, ror #9
        eor x4, x4, x28, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x4, x4, x3, ror #61
        str x13, [sp, #96]
        eor x13, x16, x23, ror #40
        eor x20, x13, x20, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x6, x13, x6, ror #19
        eor x24, x13, x24, ror #31
        eor x25, x13, x25, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x12, x13, x12, ror #2
        eor x13, x10, x2, ror #46
        eor x15, x13, x15, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x27, x13, x27, ror #3
        eor x9, x13, x9, ror #27
        eor x22, x13, x22, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x8, x13, x8
        eor x13, x2, x4, ror #31
        eor x2, x16, x4, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x11, x2, x11, ror #42
        eor x30, x2, x30, ror #36
        eor x5, x2, x5, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x17, x2, x17, ror #11
        eor x26, x2, x26, ror #63
        eor x16, x23, x10, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x7, x16, x7, ror #45
        eor x14, x16, x14, ror #44
        eor x28, x16, x28, ror #17
        eor x3, x16, x3, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x21, x16, x21, ror #35
        eor x19, x13, x19
        ldr x4, [sp, #88]
        mov v25.16b, v1.16b
        eor x4, x13, x4, ror #61
        ldr x16, [sp, #96]
        eor x16, x13, x16, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x10, [sp, #80]
        eor x10, x13, x10, ror #11
        ldr x23, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x23, x13, x23, ror #21
        mov x13, x19
        mov x2, x6
        xar v9.2d, v22.2d, v31.2d, #3
        str x20, [sp, #104]
        bic x20, x9, x6, ror #1
        eor x19, x19, x20, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x20, x17, x9, ror #39
        eor x6, x20, x6, ror #40
        bic x20, x21, x17, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x9, x20, x9, ror #58
        bic x20, x13, x21, ror #46
        eor x17, x20, x17, ror #1
        bic x20, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x21, x20, x21, ror #5
        mov x2, x11
        mov x13, x14
        xar v2.2d, v12.2d, v31.2d, #21
        bic x20, x16, x14, ror #43
        eor x11, x20, x11, ror #61
        bic x20, x25, x16, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x14, x14, x20
        bic x20, x8, x25, ror #18
        eor x16, x20, x16, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x20, x2, x8, ror #28
        eor x25, x20, x25, ror #46
        bic x20, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x8, x20, x8, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x20, x27
        str x19, [sp, #104]
        bic x19, x5, x27, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x3, x5, ror #9
        eor x27, x19, x27, ror #25
        bic x19, x23, x3, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x5, x19, x5, ror #15
        bic x19, x2, x23, ror #26
        eor x3, x19, x3, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x20, x2, ror #7
        eor x23, x19, x23, ror #33
        mov x20, x7
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x4
        bic x19, x24, x4, ror #17
        eor x7, x19, x7, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x22, x24, ror #7
        eor x4, x19, x4, ror #24
        bic x19, x26, x22, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x24, x19, x24, ror #45
        bic x19, x20, x26, ror #61
        eor x22, x19, x22, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x20, ror #5
        eor x26, x19, x26, ror #2
        mov x2, x15
        xar v3.2d, v18.2d, v27.2d, #43
        mov x20, x30
        bic x19, x28, x30, ror #10
        eor x15, x15, x19
        bic x19, x10, x28, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x30, x19, x30, ror #8
        bic x19, x12, x10, ror #4
        eor x28, x19, x28, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x12, ror #62
        eor x10, x19, x10, ror #2
        bic x19, x20, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x12, x19, x12, ror #52
        ldr x20, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x20
        eor x20, x11, x2, ror #3
        eor x20, x20, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x20, x20, x7, ror #14
        eor x20, x20, x15, ror #24
        eor x19, x6, x14, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x27, ror #51
        eor x19, x19, x4, ror #3
        eor x19, x19, x30, ror #22
        mov v30.16b, v1.16b
        str x15, [sp, #104]
        eor x15, x16, x9, ror #24
        eor x15, x15, x5, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x15, x15, x24, ror #8
        eor x15, x15, x28, ror #61
        str x11, [sp, #80]
        eor x11, x3, x17, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x11, x11, x25, ror #38
        eor x11, x11, x22, ror #13
        eor x11, x11, x10, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x7, [sp, #96]
        eor x7, x12, x21, ror #10
        eor x7, x7, x8, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x7, x7, x23, ror #46
        eor x7, x7, x26, ror #61
        str x13, [sp, #88]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x15, x20, ror #40
        eor x6, x13, x6, ror #44
        eor x14, x13, x14, ror #19
        mov v29.16b, v5.16b
        eor x27, x13, x27, ror #31
        eor x4, x13, x4, ror #47
        eor x30, x13, x30, ror #2
        mov v30.16b, v6.16b
        eor x13, x11, x19, ror #46
        eor x9, x13, x9, ror #27
        eor x16, x13, x16, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x5, x13, x5, ror #27
        eor x24, x13, x24, ror #11
        eor x28, x13, x28
        eor x13, x19, x7, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x15, x7, ror #8
        eor x17, x19, x17, ror #42
        eor x25, x19, x25, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x3, x19, x3, ror #62
        eor x22, x19, x22, ror #11
        eor x10, x19, x10, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x15, x20, x11, ror #24
        eor x21, x15, x21, ror #45
        eor x8, x15, x8, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x23, x15, x23, ror #17
        eor x26, x15, x26, ror #32
        eor x12, x15, x12, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x7, [sp, #80]
        eor x7, x13, x7, ror #61
        mov v30.16b, v11.16b
        ldr x15, [sp, #88]
        eor x15, x13, x15, ror #61
        ldr x11, [sp, #96]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x11, x13, x11, ror #11
        ldr x20, [sp, #104]
        eor x20, x13, x20, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x14
        str x6, [sp, #104]
        bic x6, x5, x14, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x6, ror #40
        bic x6, x22, x5, ror #39
        eor x14, x6, x14, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x6, x12, x22, ror #19
        eor x5, x6, x5, ror #58
        bic x6, x13, x12, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x22, x6, x22, ror #1
        bic x6, x19, x13, ror #23
        eor x12, x6, x12, ror #5
        mov v29.16b, v15.16b
        mov x19, x17
        mov x13, x8
        bic x6, x15, x8, ror #43
        mov v30.16b, v16.16b
        eor x17, x6, x17, ror #61
        bic x6, x4, x15, ror #21
        eor x8, x8, x6
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x6, x28, x4, ror #18
        eor x15, x6, x15, ror #39
        bic x6, x19, x28, ror #28
        eor x4, x6, x4, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x6, x13, x19, ror #18
        eor x28, x6, x28, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x6, x16
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x3, x16, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x26, x3, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x16, x2, x16, ror #25
        bic x2, x20, x26, ror #6
        eor x3, x2, x3, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x20, ror #26
        eor x26, x2, x26, ror #32
        bic x2, x6, x19, ror #7
        mov v30.16b, v21.16b
        eor x20, x2, x20, ror #33
        mov x6, x21
        mov x19, x7
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x27, x7, ror #17
        eor x21, x2, x21, ror #22
        bic x2, x24, x27, ror #7
        eor x7, x2, x7, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x10, x24, ror #38
        eor x27, x2, x27, ror #45
        bic x2, x6, x10, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x24, x2, x24, ror #35
        bic x2, x19, x6, ror #5
        eor x10, x2, x10, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x9
        mov x6, x25
        bic x2, x23, x25, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x9, x9, x2
        bic x2, x11, x23, ror #62
        eor x25, x2, x25, ror #8
        ldr d31, [x1, #80]
        bic x2, x30, x11, ror #4
        eor x23, x2, x23, ror #2
        bic x2, x19, x30, ror #62
        dup v31.2d, v31.d[0]
        eor x11, x2, x11, ror #2
        bic x2, x6, x19, ror #54
        eor x30, x2, x30, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x6, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x6
        eor x6, x17, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x6, x6, x13
        eor x6, x6, x21, ror #14
        eor x6, x6, x9, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x14, x8, ror #39
        eor x2, x2, x16, ror #51
        eor x2, x2, x7, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x25, ror #22
        str x9, [sp, #104]
        eor x9, x15, x5, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x9, x9, x3, ror #24
        eor x9, x9, x27, ror #8
        eor x9, x9, x23, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x17, [sp, #96]
        eor x17, x26, x22, ror #44
        eor x17, x17, x4, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x17, x17, x24, ror #13
        eor x17, x17, x11, ror #1
        str x21, [sp, #88]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x21, x30, x12, ror #10
        eor x21, x21, x28, ror #9
        eor x21, x21, x20, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x21, x21, x10, ror #61
        str x13, [sp, #80]
        eor x13, x9, x6, ror #40
        eor x14, x13, x14, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x8, x13, x8, ror #19
        eor x16, x13, x16, ror #31
        eor x7, x13, x7, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x25, x13, x25, ror #2
        eor x13, x17, x2, ror #46
        eor x5, x13, x5, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x15, x13, x15, ror #3
        eor x3, x13, x3, ror #27
        eor x27, x13, x27, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x23, x13, x23
        eor x13, x2, x21, ror #31
        eor x2, x9, x21, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x22, x2, x22, ror #42
        eor x4, x2, x4, ror #36
        eor x26, x2, x26, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x24, x2, x24, ror #11
        eor x11, x2, x11, ror #63
        eor x9, x6, x17, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x12, x9, x12, ror #45
        eor x28, x9, x28, ror #44
        eor x20, x9, x20, ror #17
        eor x10, x9, x10, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x30, x9, x30, ror #35
        eor x19, x13, x19
        ldr x21, [sp, #96]
        mov v25.16b, v1.16b
        eor x21, x13, x21, ror #61
        ldr x9, [sp, #80]
        eor x9, x13, x9, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x17, [sp, #88]
        eor x17, x13, x17, ror #11
        ldr x6, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x6, x13, x6, ror #21
        mov x13, x19
        mov x2, x8
        xar v9.2d, v22.2d, v31.2d, #3
        str x14, [sp, #104]
        bic x14, x3, x8, ror #1
        eor x19, x19, x14, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x14, x24, x3, ror #39
        eor x8, x14, x8, ror #40
        bic x14, x30, x24, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x3, x14, x3, ror #58
        bic x14, x13, x30, ror #46
        eor x24, x14, x24, ror #1
        bic x14, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x30, x14, x30, ror #5
        mov x2, x22
        mov x13, x28
        xar v2.2d, v12.2d, v31.2d, #21
        bic x14, x9, x28, ror #43
        eor x22, x14, x22, ror #61
        bic x14, x7, x9, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x28, x28, x14
        bic x14, x23, x7, ror #18
        eor x9, x14, x9, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x14, x2, x23, ror #28
        eor x7, x14, x7, ror #46
        bic x14, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x23, x14, x23, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x14, x15
        str x19, [sp, #104]
        bic x19, x26, x15, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x10, x26, ror #9
        eor x15, x19, x15, ror #25
        bic x19, x6, x10, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x26, x19, x26, ror #15
        bic x19, x2, x6, ror #26
        eor x10, x19, x10, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x14, x2, ror #7
        eor x6, x19, x6, ror #33
        mov x14, x12
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x21
        bic x19, x16, x21, ror #17
        eor x12, x19, x12, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x27, x16, ror #7
        eor x21, x19, x21, ror #24
        bic x19, x11, x27, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x16, x19, x16, ror #45
        bic x19, x14, x11, ror #61
        eor x27, x19, x27, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x14, ror #5
        eor x11, x19, x11, ror #2
        mov x2, x5
        xar v3.2d, v18.2d, v27.2d, #43
        mov x14, x4
        bic x19, x20, x4, ror #10
        eor x5, x5, x19
        bic x19, x17, x20, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x4, x19, x4, ror #8
        bic x19, x25, x17, ror #4
        eor x20, x19, x20, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x25, ror #62
        eor x17, x19, x17, ror #2
        bic x19, x14, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x25, x19, x25, ror #52
        ldr x14, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x14
        eor x14, x22, x2, ror #3
        eor x14, x14, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x14, x14, x12, ror #14
        eor x14, x14, x5, ror #24
        eor x19, x8, x28, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x15, ror #51
        eor x19, x19, x21, ror #3
        eor x19, x19, x4, ror #22
        mov v30.16b, v1.16b
        str x5, [sp, #104]
        eor x5, x9, x3, ror #24
        eor x5, x5, x26, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x5, x5, x16, ror #8
        eor x5, x5, x20, ror #61
        str x22, [sp, #88]
        eor x22, x10, x24, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x22, x22, x7, ror #38
        eor x22, x22, x27, ror #13
        eor x22, x22, x17, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x12, [sp, #80]
        eor x12, x25, x30, ror #10
        eor x12, x12, x23, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x12, x12, x6, ror #46
        eor x12, x12, x11, ror #61
        str x13, [sp, #96]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x5, x14, ror #40
        eor x8, x13, x8, ror #44
        eor x28, x13, x28, ror #19
        mov v29.16b, v5.16b
        eor x15, x13, x15, ror #31
        eor x21, x13, x21, ror #47
        eor x4, x13, x4, ror #2
        mov v30.16b, v6.16b
        eor x13, x22, x19, ror #46
        eor x3, x13, x3, ror #27
        eor x9, x13, x9, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x26, x13, x26, ror #27
        eor x16, x13, x16, ror #11
        eor x20, x13, x20
        eor x13, x19, x12, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x5, x12, ror #8
        eor x24, x19, x24, ror #42
        eor x7, x19, x7, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x10, x19, x10, ror #62
        eor x27, x19, x27, ror #11
        eor x17, x19, x17, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x5, x14, x22, ror #24
        eor x30, x5, x30, ror #45
        eor x23, x5, x23, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x6, x5, x6, ror #17
        eor x11, x5, x11, ror #32
        eor x25, x5, x25, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x12, [sp, #88]
        eor x12, x13, x12, ror #61
        mov v30.16b, v11.16b
        ldr x5, [sp, #96]
        eor x5, x13, x5, ror #61
        ldr x22, [sp, #80]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x22, x13, x22, ror #11
        ldr x14, [sp, #104]
        eor x14, x13, x14, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x28
        str x8, [sp, #104]
        bic x8, x26, x28, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x8, ror #40
        bic x8, x27, x26, ror #39
        eor x28, x8, x28, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x8, x25, x27, ror #19
        eor x26, x8, x26, ror #58
        bic x8, x13, x25, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x27, x8, x27, ror #1
        bic x8, x19, x13, ror #23
        eor x25, x8, x25, ror #5
        mov v29.16b, v15.16b
        mov x19, x24
        mov x13, x23
        bic x8, x5, x23, ror #43
        mov v30.16b, v16.16b
        eor x24, x8, x24, ror #61
        bic x8, x21, x5, ror #21
        eor x23, x23, x8
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x8, x20, x21, ror #18
        eor x5, x8, x5, ror #39
        bic x8, x19, x20, ror #28
        eor x21, x8, x21, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x8, x13, x19, ror #18
        eor x20, x8, x20, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x8, x9
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x10, x9, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x11, x10, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x9, x2, x9, ror #25
        bic x2, x14, x11, ror #6
        eor x10, x2, x10, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x14, ror #26
        eor x11, x2, x11, ror #32
        bic x2, x8, x19, ror #7
        mov v30.16b, v21.16b
        eor x14, x2, x14, ror #33
        mov x8, x30
        mov x19, x12
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x15, x12, ror #17
        eor x30, x2, x30, ror #22
        bic x2, x16, x15, ror #7
        eor x12, x2, x12, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x17, x16, ror #38
        eor x15, x2, x15, ror #45
        bic x2, x8, x17, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x16, x2, x16, ror #35
        bic x2, x19, x8, ror #5
        eor x17, x2, x17, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x3
        mov x8, x7
        bic x2, x6, x7, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x3, x3, x2
        bic x2, x22, x6, ror #62
        eor x7, x2, x7, ror #8
        ldr d31, [x1, #72]
        bic x2, x4, x22, ror #4
        eor x6, x2, x6, ror #2
        bic x2, x19, x4, ror #62
        dup v31.2d, v31.d[0]
        eor x22, x2, x22, ror #2
        bic x2, x8, x19, ror #54
        eor x4, x2, x4, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x8, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x8
        eor x8, x24, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x8, x8, x13
        eor x8, x8, x30, ror #14
        eor x8, x8, x3, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x28, x23, ror #39
        eor x2, x2, x9, ror #51
        eor x2, x2, x12, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x7, ror #22
        str x3, [sp, #104]
        eor x3, x5, x26, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x3, x3, x10, ror #24
        eor x3, x3, x15, ror #8
        eor x3, x3, x6, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x24, [sp, #80]
        eor x24, x11, x27, ror #44
        eor x24, x24, x21, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x24, x24, x16, ror #13
        eor x24, x24, x22, ror #1
        str x30, [sp, #96]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x30, x4, x25, ror #10
        eor x30, x30, x20, ror #9
        eor x30, x30, x14, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x30, x30, x17, ror #61
        str x13, [sp, #88]
        eor x13, x3, x8, ror #40
        eor x28, x13, x28, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x23, x13, x23, ror #19
        eor x9, x13, x9, ror #31
        eor x12, x13, x12, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x7, x13, x7, ror #2
        eor x13, x24, x2, ror #46
        eor x26, x13, x26, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x5, x13, x5, ror #3
        eor x10, x13, x10, ror #27
        eor x15, x13, x15, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x6, x13, x6
        eor x13, x2, x30, ror #31
        eor x2, x3, x30, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x27, x2, x27, ror #42
        eor x21, x2, x21, ror #36
        eor x11, x2, x11, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x16, x2, x16, ror #11
        eor x22, x2, x22, ror #63
        eor x3, x8, x24, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x25, x3, x25, ror #45
        eor x20, x3, x20, ror #44
        eor x14, x3, x14, ror #17
        eor x17, x3, x17, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x4, x3, x4, ror #35
        eor x19, x13, x19
        ldr x30, [sp, #80]
        mov v25.16b, v1.16b
        eor x30, x13, x30, ror #61
        ldr x3, [sp, #88]
        eor x3, x13, x3, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x24, [sp, #96]
        eor x24, x13, x24, ror #11
        ldr x8, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x8, x13, x8, ror #21
        mov x13, x19
        mov x2, x23
        xar v9.2d, v22.2d, v31.2d, #3
        str x28, [sp, #104]
        bic x28, x10, x23, ror #1
        eor x19, x19, x28, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x28, x16, x10, ror #39
        eor x23, x28, x23, ror #40
        bic x28, x4, x16, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x10, x28, x10, ror #58
        bic x28, x13, x4, ror #46
        eor x16, x28, x16, ror #1
        bic x28, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x4, x28, x4, ror #5
        mov x2, x27
        mov x13, x20
        xar v2.2d, v12.2d, v31.2d, #21
        bic x28, x3, x20, ror #43
        eor x27, x28, x27, ror #61
        bic x28, x12, x3, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x20, x20, x28
        bic x28, x6, x12, ror #18
        eor x3, x28, x3, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x28, x2, x6, ror #28
        eor x12, x28, x12, ror #46
        bic x28, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x6, x28, x6, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x28, x5
        str x19, [sp, #104]
        bic x19, x11, x5, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x17, x11, ror #9
        eor x5, x19, x5, ror #25
        bic x19, x8, x17, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x11, x19, x11, ror #15
        bic x19, x2, x8, ror #26
        eor x17, x19, x17, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x28, x2, ror #7
        eor x8, x19, x8, ror #33
        mov x28, x25
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x30
        bic x19, x9, x30, ror #17
        eor x25, x19, x25, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x15, x9, ror #7
        eor x30, x19, x30, ror #24
        bic x19, x22, x15, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x9, x19, x9, ror #45
        bic x19, x28, x22, ror #61
        eor x15, x19, x15, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x28, ror #5
        eor x22, x19, x22, ror #2
        mov x2, x26
        xar v3.2d, v18.2d, v27.2d, #43
        mov x28, x21
        bic x19, x14, x21, ror #10
        eor x26, x26, x19
        bic x19, x24, x14, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x21, x19, x21, ror #8
        bic x19, x7, x24, ror #4
        eor x14, x19, x14, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x7, ror #62
        eor x24, x19, x24, ror #2
        bic x19, x28, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x7, x19, x7, ror #52
        ldr x28, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x28
        eor x28, x27, x2, ror #3
        eor x28, x28, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x28, x28, x25, ror #14
        eor x28, x28, x26, ror #24
        eor x19, x23, x20, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x5, ror #51
        eor x19, x19, x30, ror #3
        eor x19, x19, x21, ror #22
        mov v30.16b, v1.16b
        str x26, [sp, #104]
        eor x26, x3, x10, ror #24
        eor x26, x26, x11, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x26, x26, x9, ror #8
        eor x26, x26, x14, ror #61
        str x27, [sp, #96]
        eor x27, x17, x16, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x27, x27, x12, ror #38
        eor x27, x27, x15, ror #13
        eor x27, x27, x24, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x25, [sp, #88]
        eor x25, x7, x4, ror #10
        eor x25, x25, x6, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x25, x25, x8, ror #46
        eor x25, x25, x22, ror #61
        str x13, [sp, #80]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x26, x28, ror #40
        eor x23, x13, x23, ror #44
        eor x20, x13, x20, ror #19
        mov v29.16b, v5.16b
        eor x5, x13, x5, ror #31
        eor x30, x13, x30, ror #47
        eor x21, x13, x21, ror #2
        mov v30.16b, v6.16b
        eor x13, x27, x19, ror #46
        eor x10, x13, x10, ror #27
        eor x3, x13, x3, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x11, x13, x11, ror #27
        eor x9, x13, x9, ror #11
        eor x14, x13, x14
        eor x13, x19, x25, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x26, x25, ror #8
        eor x16, x19, x16, ror #42
        eor x12, x19, x12, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x17, x19, x17, ror #62
        eor x15, x19, x15, ror #11
        eor x24, x19, x24, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x26, x28, x27, ror #24
        eor x4, x26, x4, ror #45
        eor x6, x26, x6, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x8, x26, x8, ror #17
        eor x22, x26, x22, ror #32
        eor x7, x26, x7, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x25, [sp, #96]
        eor x25, x13, x25, ror #61
        mov v30.16b, v11.16b
        ldr x26, [sp, #80]
        eor x26, x13, x26, ror #61
        ldr x27, [sp, #88]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x27, x13, x27, ror #11
        ldr x28, [sp, #104]
        eor x28, x13, x28, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x20
        str x23, [sp, #104]
        bic x23, x11, x20, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x23, ror #40
        bic x23, x15, x11, ror #39
        eor x20, x23, x20, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x23, x7, x15, ror #19
        eor x11, x23, x11, ror #58
        bic x23, x13, x7, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x15, x23, x15, ror #1
        bic x23, x19, x13, ror #23
        eor x7, x23, x7, ror #5
        mov v29.16b, v15.16b
        mov x19, x16
        mov x13, x6
        bic x23, x26, x6, ror #43
        mov v30.16b, v16.16b
        eor x16, x23, x16, ror #61
        bic x23, x30, x26, ror #21
        eor x6, x6, x23
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x23, x14, x30, ror #18
        eor x26, x23, x26, ror #39
        bic x23, x19, x14, ror #28
        eor x30, x23, x30, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x23, x13, x19, ror #18
        eor x14, x23, x14, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x23, x3
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x17, x3, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x22, x17, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x3, x2, x3, ror #25
        bic x2, x28, x22, ror #6
        eor x17, x2, x17, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x28, ror #26
        eor x22, x2, x22, ror #32
        bic x2, x23, x19, ror #7
        mov v30.16b, v21.16b
        eor x28, x2, x28, ror #33
        mov x23, x4
        mov x19, x25
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x5, x25, ror #17
        eor x4, x2, x4, ror #22
        bic x2, x9, x5, ror #7
        eor x25, x2, x25, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x24, x9, ror #38
        eor x5, x2, x5, ror #45
        bic x2, x23, x24, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x9, x2, x9, ror #35
        bic x2, x19, x23, ror #5
        eor x24, x2, x24, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x10
        mov x23, x12
        bic x2, x8, x12, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x10, x10, x2
        bic x2, x27, x8, ror #62
        eor x12, x2, x12, ror #8
        ldr d31, [x1, #64]
        bic x2, x21, x27, ror #4
        eor x8, x2, x8, ror #2
        bic x2, x19, x21, ror #62
        dup v31.2d, v31.d[0]
        eor x27, x2, x27, ror #2
        bic x2, x23, x19, ror #54
        eor x21, x2, x21, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x23, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x23
        eor x23, x16, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x23, x23, x13
        eor x23, x23, x4, ror #14
        eor x23, x23, x10, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x20, x6, ror #39
        eor x2, x2, x3, ror #51
        eor x2, x2, x25, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x12, ror #22
        str x10, [sp, #104]
        eor x10, x26, x11, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x10, x10, x17, ror #24
        eor x10, x10, x5, ror #8
        eor x10, x10, x8, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x16, [sp, #88]
        eor x16, x22, x15, ror #44
        eor x16, x16, x30, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x16, x16, x9, ror #13
        eor x16, x16, x27, ror #1
        str x4, [sp, #80]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x4, x21, x7, ror #10
        eor x4, x4, x14, ror #9
        eor x4, x4, x28, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x4, x4, x24, ror #61
        str x13, [sp, #96]
        eor x13, x10, x23, ror #40
        eor x20, x13, x20, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x6, x13, x6, ror #19
        eor x3, x13, x3, ror #31
        eor x25, x13, x25, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x12, x13, x12, ror #2
        eor x13, x16, x2, ror #46
        eor x11, x13, x11, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x26, x13, x26, ror #3
        eor x17, x13, x17, ror #27
        eor x5, x13, x5, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x8, x13, x8
        eor x13, x2, x4, ror #31
        eor x2, x10, x4, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x15, x2, x15, ror #42
        eor x30, x2, x30, ror #36
        eor x22, x2, x22, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x9, x2, x9, ror #11
        eor x27, x2, x27, ror #63
        eor x10, x23, x16, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x7, x10, x7, ror #45
        eor x14, x10, x14, ror #44
        eor x28, x10, x28, ror #17
        eor x24, x10, x24, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x21, x10, x21, ror #35
        eor x19, x13, x19
        ldr x4, [sp, #88]
        mov v25.16b, v1.16b
        eor x4, x13, x4, ror #61
        ldr x10, [sp, #96]
        eor x10, x13, x10, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x16, [sp, #80]
        eor x16, x13, x16, ror #11
        ldr x23, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x23, x13, x23, ror #21
        mov x13, x19
        mov x2, x6
        xar v9.2d, v22.2d, v31.2d, #3
        str x20, [sp, #104]
        bic x20, x17, x6, ror #1
        eor x19, x19, x20, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x20, x9, x17, ror #39
        eor x6, x20, x6, ror #40
        bic x20, x21, x9, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x17, x20, x17, ror #58
        bic x20, x13, x21, ror #46
        eor x9, x20, x9, ror #1
        bic x20, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x21, x20, x21, ror #5
        mov x2, x15
        mov x13, x14
        xar v2.2d, v12.2d, v31.2d, #21
        bic x20, x10, x14, ror #43
        eor x15, x20, x15, ror #61
        bic x20, x25, x10, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x14, x14, x20
        bic x20, x8, x25, ror #18
        eor x10, x20, x10, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x20, x2, x8, ror #28
        eor x25, x20, x25, ror #46
        bic x20, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x8, x20, x8, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x20, x26
        str x19, [sp, #104]
        bic x19, x22, x26, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x24, x22, ror #9
        eor x26, x19, x26, ror #25
        bic x19, x23, x24, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x22, x19, x22, ror #15
        bic x19, x2, x23, ror #26
        eor x24, x19, x24, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x20, x2, ror #7
        eor x23, x19, x23, ror #33
        mov x20, x7
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x4
        bic x19, x3, x4, ror #17
        eor x7, x19, x7, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x5, x3, ror #7
        eor x4, x19, x4, ror #24
        bic x19, x27, x5, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x3, x19, x3, ror #45
        bic x19, x20, x27, ror #61
        eor x5, x19, x5, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x20, ror #5
        eor x27, x19, x27, ror #2
        mov x2, x11
        xar v3.2d, v18.2d, v27.2d, #43
        mov x20, x30
        bic x19, x28, x30, ror #10
        eor x11, x11, x19
        bic x19, x16, x28, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x30, x19, x30, ror #8
        bic x19, x12, x16, ror #4
        eor x28, x19, x28, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x12, ror #62
        eor x16, x19, x16, ror #2
        bic x19, x20, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x12, x19, x12, ror #52
        ldr x20, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x20
        eor x20, x15, x2, ror #3
        eor x20, x20, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x20, x20, x7, ror #14
        eor x20, x20, x11, ror #24
        eor x19, x6, x14, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x26, ror #51
        eor x19, x19, x4, ror #3
        eor x19, x19, x30, ror #22
        mov v30.16b, v1.16b
        str x11, [sp, #104]
        eor x11, x10, x17, ror #24
        eor x11, x11, x22, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x11, x11, x3, ror #8
        eor x11, x11, x28, ror #61
        str x15, [sp, #80]
        eor x15, x24, x9, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x15, x15, x25, ror #38
        eor x15, x15, x5, ror #13
        eor x15, x15, x16, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x7, [sp, #96]
        eor x7, x12, x21, ror #10
        eor x7, x7, x8, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x7, x7, x23, ror #46
        eor x7, x7, x27, ror #61
        str x13, [sp, #88]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x11, x20, ror #40
        eor x6, x13, x6, ror #44
        eor x14, x13, x14, ror #19
        mov v29.16b, v5.16b
        eor x26, x13, x26, ror #31
        eor x4, x13, x4, ror #47
        eor x30, x13, x30, ror #2
        mov v30.16b, v6.16b
        eor x13, x15, x19, ror #46
        eor x17, x13, x17, ror #27
        eor x10, x13, x10, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x22, x13, x22, ror #27
        eor x3, x13, x3, ror #11
        eor x28, x13, x28
        eor x13, x19, x7, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x11, x7, ror #8
        eor x9, x19, x9, ror #42
        eor x25, x19, x25, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x24, x19, x24, ror #62
        eor x5, x19, x5, ror #11
        eor x16, x19, x16, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x11, x20, x15, ror #24
        eor x21, x11, x21, ror #45
        eor x8, x11, x8, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x23, x11, x23, ror #17
        eor x27, x11, x27, ror #32
        eor x12, x11, x12, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x7, [sp, #80]
        eor x7, x13, x7, ror #61
        mov v30.16b, v11.16b
        ldr x11, [sp, #88]
        eor x11, x13, x11, ror #61
        ldr x15, [sp, #96]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x15, x13, x15, ror #11
        ldr x20, [sp, #104]
        eor x20, x13, x20, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x14
        str x6, [sp, #104]
        bic x6, x22, x14, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x6, ror #40
        bic x6, x5, x22, ror #39
        eor x14, x6, x14, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x6, x12, x5, ror #19
        eor x22, x6, x22, ror #58
        bic x6, x13, x12, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x5, x6, x5, ror #1
        bic x6, x19, x13, ror #23
        eor x12, x6, x12, ror #5
        mov v29.16b, v15.16b
        mov x19, x9
        mov x13, x8
        bic x6, x11, x8, ror #43
        mov v30.16b, v16.16b
        eor x9, x6, x9, ror #61
        bic x6, x4, x11, ror #21
        eor x8, x8, x6
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x6, x28, x4, ror #18
        eor x11, x6, x11, ror #39
        bic x6, x19, x28, ror #28
        eor x4, x6, x4, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x6, x13, x19, ror #18
        eor x28, x6, x28, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x6, x10
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x24, x10, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x27, x24, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x10, x2, x10, ror #25
        bic x2, x20, x27, ror #6
        eor x24, x2, x24, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x20, ror #26
        eor x27, x2, x27, ror #32
        bic x2, x6, x19, ror #7
        mov v30.16b, v21.16b
        eor x20, x2, x20, ror #33
        mov x6, x21
        mov x19, x7
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x26, x7, ror #17
        eor x21, x2, x21, ror #22
        bic x2, x3, x26, ror #7
        eor x7, x2, x7, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x16, x3, ror #38
        eor x26, x2, x26, ror #45
        bic x2, x6, x16, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x3, x2, x3, ror #35
        bic x2, x19, x6, ror #5
        eor x16, x2, x16, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x17
        mov x6, x25
        bic x2, x23, x25, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x17, x17, x2
        bic x2, x15, x23, ror #62
        eor x25, x2, x25, ror #8
        ldr d31, [x1, #56]
        bic x2, x30, x15, ror #4
        eor x23, x2, x23, ror #2
        bic x2, x19, x30, ror #62
        dup v31.2d, v31.d[0]
        eor x15, x2, x15, ror #2
        bic x2, x6, x19, ror #54
        eor x30, x2, x30, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x6, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x6
        eor x6, x9, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x6, x6, x13
        eor x6, x6, x21, ror #14
        eor x6, x6, x17, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x14, x8, ror #39
        eor x2, x2, x10, ror #51
        eor x2, x2, x7, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x25, ror #22
        str x17, [sp, #104]
        eor x17, x11, x22, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x17, x17, x24, ror #24
        eor x17, x17, x26, ror #8
        eor x17, x17, x23, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x9, [sp, #96]
        eor x9, x27, x5, ror #44
        eor x9, x9, x4, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x9, x9, x3, ror #13
        eor x9, x9, x15, ror #1
        str x21, [sp, #88]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x21, x30, x12, ror #10
        eor x21, x21, x28, ror #9
        eor x21, x21, x20, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x21, x21, x16, ror #61
        str x13, [sp, #80]
        eor x13, x17, x6, ror #40
        eor x14, x13, x14, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x8, x13, x8, ror #19
        eor x10, x13, x10, ror #31
        eor x7, x13, x7, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x25, x13, x25, ror #2
        eor x13, x9, x2, ror #46
        eor x22, x13, x22, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x11, x13, x11, ror #3
        eor x24, x13, x24, ror #27
        eor x26, x13, x26, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x23, x13, x23
        eor x13, x2, x21, ror #31
        eor x2, x17, x21, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x5, x2, x5, ror #42
        eor x4, x2, x4, ror #36
        eor x27, x2, x27, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x3, x2, x3, ror #11
        eor x15, x2, x15, ror #63
        eor x17, x6, x9, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x12, x17, x12, ror #45
        eor x28, x17, x28, ror #44
        eor x20, x17, x20, ror #17
        eor x16, x17, x16, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x30, x17, x30, ror #35
        eor x19, x13, x19
        ldr x21, [sp, #96]
        mov v25.16b, v1.16b
        eor x21, x13, x21, ror #61
        ldr x17, [sp, #80]
        eor x17, x13, x17, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x9, [sp, #88]
        eor x9, x13, x9, ror #11
        ldr x6, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x6, x13, x6, ror #21
        mov x13, x19
        mov x2, x8
        xar v9.2d, v22.2d, v31.2d, #3
        str x14, [sp, #104]
        bic x14, x24, x8, ror #1
        eor x19, x19, x14, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x14, x3, x24, ror #39
        eor x8, x14, x8, ror #40
        bic x14, x30, x3, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x24, x14, x24, ror #58
        bic x14, x13, x30, ror #46
        eor x3, x14, x3, ror #1
        bic x14, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x30, x14, x30, ror #5
        mov x2, x5
        mov x13, x28
        xar v2.2d, v12.2d, v31.2d, #21
        bic x14, x17, x28, ror #43
        eor x5, x14, x5, ror #61
        bic x14, x7, x17, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x28, x28, x14
        bic x14, x23, x7, ror #18
        eor x17, x14, x17, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x14, x2, x23, ror #28
        eor x7, x14, x7, ror #46
        bic x14, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x23, x14, x23, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x14, x11
        str x19, [sp, #104]
        bic x19, x27, x11, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x16, x27, ror #9
        eor x11, x19, x11, ror #25
        bic x19, x6, x16, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x27, x19, x27, ror #15
        bic x19, x2, x6, ror #26
        eor x16, x19, x16, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x14, x2, ror #7
        eor x6, x19, x6, ror #33
        mov x14, x12
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x21
        bic x19, x10, x21, ror #17
        eor x12, x19, x12, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x26, x10, ror #7
        eor x21, x19, x21, ror #24
        bic x19, x15, x26, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x10, x19, x10, ror #45
        bic x19, x14, x15, ror #61
        eor x26, x19, x26, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x14, ror #5
        eor x15, x19, x15, ror #2
        mov x2, x22
        xar v3.2d, v18.2d, v27.2d, #43
        mov x14, x4
        bic x19, x20, x4, ror #10
        eor x22, x22, x19
        bic x19, x9, x20, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x4, x19, x4, ror #8
        bic x19, x25, x9, ror #4
        eor x20, x19, x20, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x25, ror #62
        eor x9, x19, x9, ror #2
        bic x19, x14, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x25, x19, x25, ror #52
        ldr x14, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x14
        eor x14, x5, x2, ror #3
        eor x14, x14, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x14, x14, x12, ror #14
        eor x14, x14, x22, ror #24
        eor x19, x8, x28, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x11, ror #51
        eor x19, x19, x21, ror #3
        eor x19, x19, x4, ror #22
        mov v30.16b, v1.16b
        str x22, [sp, #104]
        eor x22, x17, x24, ror #24
        eor x22, x22, x27, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x22, x22, x10, ror #8
        eor x22, x22, x20, ror #61
        str x5, [sp, #88]
        eor x5, x16, x3, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x5, x5, x7, ror #38
        eor x5, x5, x26, ror #13
        eor x5, x5, x9, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x12, [sp, #80]
        eor x12, x25, x30, ror #10
        eor x12, x12, x23, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x12, x12, x6, ror #46
        eor x12, x12, x15, ror #61
        str x13, [sp, #96]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x22, x14, ror #40
        eor x8, x13, x8, ror #44
        eor x28, x13, x28, ror #19
        mov v29.16b, v5.16b
        eor x11, x13, x11, ror #31
        eor x21, x13, x21, ror #47
        eor x4, x13, x4, ror #2
        mov v30.16b, v6.16b
        eor x13, x5, x19, ror #46
        eor x24, x13, x24, ror #27
        eor x17, x13, x17, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x27, x13, x27, ror #27
        eor x10, x13, x10, ror #11
        eor x20, x13, x20
        eor x13, x19, x12, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x22, x12, ror #8
        eor x3, x19, x3, ror #42
        eor x7, x19, x7, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x16, x19, x16, ror #62
        eor x26, x19, x26, ror #11
        eor x9, x19, x9, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x22, x14, x5, ror #24
        eor x30, x22, x30, ror #45
        eor x23, x22, x23, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x6, x22, x6, ror #17
        eor x15, x22, x15, ror #32
        eor x25, x22, x25, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x12, [sp, #88]
        eor x12, x13, x12, ror #61
        mov v30.16b, v11.16b
        ldr x22, [sp, #96]
        eor x22, x13, x22, ror #61
        ldr x5, [sp, #80]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x5, x13, x5, ror #11
        ldr x14, [sp, #104]
        eor x14, x13, x14, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x28
        str x8, [sp, #104]
        bic x8, x27, x28, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x8, ror #40
        bic x8, x26, x27, ror #39
        eor x28, x8, x28, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x8, x25, x26, ror #19
        eor x27, x8, x27, ror #58
        bic x8, x13, x25, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x26, x8, x26, ror #1
        bic x8, x19, x13, ror #23
        eor x25, x8, x25, ror #5
        mov v29.16b, v15.16b
        mov x19, x3
        mov x13, x23
        bic x8, x22, x23, ror #43
        mov v30.16b, v16.16b
        eor x3, x8, x3, ror #61
        bic x8, x21, x22, ror #21
        eor x23, x23, x8
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x8, x20, x21, ror #18
        eor x22, x8, x22, ror #39
        bic x8, x19, x20, ror #28
        eor x21, x8, x21, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x8, x13, x19, ror #18
        eor x20, x8, x20, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x8, x17
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x16, x17, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x15, x16, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x17, x2, x17, ror #25
        bic x2, x14, x15, ror #6
        eor x16, x2, x16, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x14, ror #26
        eor x15, x2, x15, ror #32
        bic x2, x8, x19, ror #7
        mov v30.16b, v21.16b
        eor x14, x2, x14, ror #33
        mov x8, x30
        mov x19, x12
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x11, x12, ror #17
        eor x30, x2, x30, ror #22
        bic x2, x10, x11, ror #7
        eor x12, x2, x12, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x9, x10, ror #38
        eor x11, x2, x11, ror #45
        bic x2, x8, x9, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x10, x2, x10, ror #35
        bic x2, x19, x8, ror #5
        eor x9, x2, x9, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x24
        mov x8, x7
        bic x2, x6, x7, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x24, x24, x2
        bic x2, x5, x6, ror #62
        eor x7, x2, x7, ror #8
        ldr d31, [x1, #48]
        bic x2, x4, x5, ror #4
        eor x6, x2, x6, ror #2
        bic x2, x19, x4, ror #62
        dup v31.2d, v31.d[0]
        eor x5, x2, x5, ror #2
        bic x2, x8, x19, ror #54
        eor x4, x2, x4, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x8, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x8
        eor x8, x3, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x8, x8, x13
        eor x8, x8, x30, ror #14
        eor x8, x8, x24, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x28, x23, ror #39
        eor x2, x2, x17, ror #51
        eor x2, x2, x12, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x7, ror #22
        str x24, [sp, #104]
        eor x24, x22, x27, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x24, x24, x16, ror #24
        eor x24, x24, x11, ror #8
        eor x24, x24, x6, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x3, [sp, #80]
        eor x3, x15, x26, ror #44
        eor x3, x3, x21, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x3, x3, x10, ror #13
        eor x3, x3, x5, ror #1
        str x30, [sp, #96]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x30, x4, x25, ror #10
        eor x30, x30, x20, ror #9
        eor x30, x30, x14, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x30, x30, x9, ror #61
        str x13, [sp, #88]
        eor x13, x24, x8, ror #40
        eor x28, x13, x28, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x23, x13, x23, ror #19
        eor x17, x13, x17, ror #31
        eor x12, x13, x12, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x7, x13, x7, ror #2
        eor x13, x3, x2, ror #46
        eor x27, x13, x27, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x22, x13, x22, ror #3
        eor x16, x13, x16, ror #27
        eor x11, x13, x11, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x6, x13, x6
        eor x13, x2, x30, ror #31
        eor x2, x24, x30, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x26, x2, x26, ror #42
        eor x21, x2, x21, ror #36
        eor x15, x2, x15, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x10, x2, x10, ror #11
        eor x5, x2, x5, ror #63
        eor x24, x8, x3, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x25, x24, x25, ror #45
        eor x20, x24, x20, ror #44
        eor x14, x24, x14, ror #17
        eor x9, x24, x9, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x4, x24, x4, ror #35
        eor x19, x13, x19
        ldr x30, [sp, #80]
        mov v25.16b, v1.16b
        eor x30, x13, x30, ror #61
        ldr x24, [sp, #88]
        eor x24, x13, x24, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x3, [sp, #96]
        eor x3, x13, x3, ror #11
        ldr x8, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x8, x13, x8, ror #21
        mov x13, x19
        mov x2, x23
        xar v9.2d, v22.2d, v31.2d, #3
        str x28, [sp, #104]
        bic x28, x16, x23, ror #1
        eor x19, x19, x28, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x28, x10, x16, ror #39
        eor x23, x28, x23, ror #40
        bic x28, x4, x10, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x16, x28, x16, ror #58
        bic x28, x13, x4, ror #46
        eor x10, x28, x10, ror #1
        bic x28, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x4, x28, x4, ror #5
        mov x2, x26
        mov x13, x20
        xar v2.2d, v12.2d, v31.2d, #21
        bic x28, x24, x20, ror #43
        eor x26, x28, x26, ror #61
        bic x28, x12, x24, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x20, x20, x28
        bic x28, x6, x12, ror #18
        eor x24, x28, x24, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x28, x2, x6, ror #28
        eor x12, x28, x12, ror #46
        bic x28, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x6, x28, x6, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x28, x22
        str x19, [sp, #104]
        bic x19, x15, x22, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x9, x15, ror #9
        eor x22, x19, x22, ror #25
        bic x19, x8, x9, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x15, x19, x15, ror #15
        bic x19, x2, x8, ror #26
        eor x9, x19, x9, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x28, x2, ror #7
        eor x8, x19, x8, ror #33
        mov x28, x25
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x30
        bic x19, x17, x30, ror #17
        eor x25, x19, x25, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x11, x17, ror #7
        eor x30, x19, x30, ror #24
        bic x19, x5, x11, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x17, x19, x17, ror #45
        bic x19, x28, x5, ror #61
        eor x11, x19, x11, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x28, ror #5
        eor x5, x19, x5, ror #2
        mov x2, x27
        xar v3.2d, v18.2d, v27.2d, #43
        mov x28, x21
        bic x19, x14, x21, ror #10
        eor x27, x27, x19
        bic x19, x3, x14, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x21, x19, x21, ror #8
        bic x19, x7, x3, ror #4
        eor x14, x19, x14, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x7, ror #62
        eor x3, x19, x3, ror #2
        bic x19, x28, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x7, x19, x7, ror #52
        ldr x28, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x28
        eor x28, x26, x2, ror #3
        eor x28, x28, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x28, x28, x25, ror #14
        eor x28, x28, x27, ror #24
        eor x19, x23, x20, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x22, ror #51
        eor x19, x19, x30, ror #3
        eor x19, x19, x21, ror #22
        mov v30.16b, v1.16b
        str x27, [sp, #104]
        eor x27, x24, x16, ror #24
        eor x27, x27, x15, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x27, x27, x17, ror #8
        eor x27, x27, x14, ror #61
        str x26, [sp, #96]
        eor x26, x9, x10, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x26, x26, x12, ror #38
        eor x26, x26, x11, ror #13
        eor x26, x26, x3, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x25, [sp, #88]
        eor x25, x7, x4, ror #10
        eor x25, x25, x6, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x25, x25, x8, ror #46
        eor x25, x25, x5, ror #61
        str x13, [sp, #80]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x27, x28, ror #40
        eor x23, x13, x23, ror #44
        eor x20, x13, x20, ror #19
        mov v29.16b, v5.16b
        eor x22, x13, x22, ror #31
        eor x30, x13, x30, ror #47
        eor x21, x13, x21, ror #2
        mov v30.16b, v6.16b
        eor x13, x26, x19, ror #46
        eor x16, x13, x16, ror #27
        eor x24, x13, x24, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x15, x13, x15, ror #27
        eor x17, x13, x17, ror #11
        eor x14, x13, x14
        eor x13, x19, x25, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x27, x25, ror #8
        eor x10, x19, x10, ror #42
        eor x12, x19, x12, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x9, x19, x9, ror #62
        eor x11, x19, x11, ror #11
        eor x3, x19, x3, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x27, x28, x26, ror #24
        eor x4, x27, x4, ror #45
        eor x6, x27, x6, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x8, x27, x8, ror #17
        eor x5, x27, x5, ror #32
        eor x7, x27, x7, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x25, [sp, #96]
        eor x25, x13, x25, ror #61
        mov v30.16b, v11.16b
        ldr x27, [sp, #80]
        eor x27, x13, x27, ror #61
        ldr x26, [sp, #88]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x26, x13, x26, ror #11
        ldr x28, [sp, #104]
        eor x28, x13, x28, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x20
        str x23, [sp, #104]
        bic x23, x15, x20, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x23, ror #40
        bic x23, x11, x15, ror #39
        eor x20, x23, x20, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x23, x7, x11, ror #19
        eor x15, x23, x15, ror #58
        bic x23, x13, x7, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x11, x23, x11, ror #1
        bic x23, x19, x13, ror #23
        eor x7, x23, x7, ror #5
        mov v29.16b, v15.16b
        mov x19, x10
        mov x13, x6
        bic x23, x27, x6, ror #43
        mov v30.16b, v16.16b
        eor x10, x23, x10, ror #61
        bic x23, x30, x27, ror #21
        eor x6, x6, x23
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x23, x14, x30, ror #18
        eor x27, x23, x27, ror #39
        bic x23, x19, x14, ror #28
        eor x30, x23, x30, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x23, x13, x19, ror #18
        eor x14, x23, x14, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x23, x24
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x9, x24, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x5, x9, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x24, x2, x24, ror #25
        bic x2, x28, x5, ror #6
        eor x9, x2, x9, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x28, ror #26
        eor x5, x2, x5, ror #32
        bic x2, x23, x19, ror #7
        mov v30.16b, v21.16b
        eor x28, x2, x28, ror #33
        mov x23, x4
        mov x19, x25
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x22, x25, ror #17
        eor x4, x2, x4, ror #22
        bic x2, x17, x22, ror #7
        eor x25, x2, x25, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x3, x17, ror #38
        eor x22, x2, x22, ror #45
        bic x2, x23, x3, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x17, x2, x17, ror #35
        bic x2, x19, x23, ror #5
        eor x3, x2, x3, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x16
        mov x23, x12
        bic x2, x8, x12, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x16, x16, x2
        bic x2, x26, x8, ror #62
        eor x12, x2, x12, ror #8
        ldr d31, [x1, #40]
        bic x2, x21, x26, ror #4
        eor x8, x2, x8, ror #2
        bic x2, x19, x21, ror #62
        dup v31.2d, v31.d[0]
        eor x26, x2, x26, ror #2
        bic x2, x23, x19, ror #54
        eor x21, x2, x21, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x23, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x23
        eor x23, x10, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x23, x23, x13
        eor x23, x23, x4, ror #14
        eor x23, x23, x16, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x20, x6, ror #39
        eor x2, x2, x24, ror #51
        eor x2, x2, x25, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x12, ror #22
        str x16, [sp, #104]
        eor x16, x27, x15, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x16, x16, x9, ror #24
        eor x16, x16, x22, ror #8
        eor x16, x16, x8, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x10, [sp, #88]
        eor x10, x5, x11, ror #44
        eor x10, x10, x30, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x10, x10, x17, ror #13
        eor x10, x10, x26, ror #1
        str x4, [sp, #80]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x4, x21, x7, ror #10
        eor x4, x4, x14, ror #9
        eor x4, x4, x28, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x4, x4, x3, ror #61
        str x13, [sp, #96]
        eor x13, x16, x23, ror #40
        eor x20, x13, x20, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x6, x13, x6, ror #19
        eor x24, x13, x24, ror #31
        eor x25, x13, x25, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x12, x13, x12, ror #2
        eor x13, x10, x2, ror #46
        eor x15, x13, x15, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x27, x13, x27, ror #3
        eor x9, x13, x9, ror #27
        eor x22, x13, x22, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x8, x13, x8
        eor x13, x2, x4, ror #31
        eor x2, x16, x4, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x11, x2, x11, ror #42
        eor x30, x2, x30, ror #36
        eor x5, x2, x5, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x17, x2, x17, ror #11
        eor x26, x2, x26, ror #63
        eor x16, x23, x10, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x7, x16, x7, ror #45
        eor x14, x16, x14, ror #44
        eor x28, x16, x28, ror #17
        eor x3, x16, x3, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x21, x16, x21, ror #35
        eor x19, x13, x19
        ldr x4, [sp, #88]
        mov v25.16b, v1.16b
        eor x4, x13, x4, ror #61
        ldr x16, [sp, #96]
        eor x16, x13, x16, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x10, [sp, #80]
        eor x10, x13, x10, ror #11
        ldr x23, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x23, x13, x23, ror #21
        mov x13, x19
        mov x2, x6
        xar v9.2d, v22.2d, v31.2d, #3
        str x20, [sp, #104]
        bic x20, x9, x6, ror #1
        eor x19, x19, x20, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x20, x17, x9, ror #39
        eor x6, x20, x6, ror #40
        bic x20, x21, x17, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x9, x20, x9, ror #58
        bic x20, x13, x21, ror #46
        eor x17, x20, x17, ror #1
        bic x20, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x21, x20, x21, ror #5
        mov x2, x11
        mov x13, x14
        xar v2.2d, v12.2d, v31.2d, #21
        bic x20, x16, x14, ror #43
        eor x11, x20, x11, ror #61
        bic x20, x25, x16, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x14, x14, x20
        bic x20, x8, x25, ror #18
        eor x16, x20, x16, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x20, x2, x8, ror #28
        eor x25, x20, x25, ror #46
        bic x20, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x8, x20, x8, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x20, x27
        str x19, [sp, #104]
        bic x19, x5, x27, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x3, x5, ror #9
        eor x27, x19, x27, ror #25
        bic x19, x23, x3, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x5, x19, x5, ror #15
        bic x19, x2, x23, ror #26
        eor x3, x19, x3, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x20, x2, ror #7
        eor x23, x19, x23, ror #33
        mov x20, x7
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x4
        bic x19, x24, x4, ror #17
        eor x7, x19, x7, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x22, x24, ror #7
        eor x4, x19, x4, ror #24
        bic x19, x26, x22, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x24, x19, x24, ror #45
        bic x19, x20, x26, ror #61
        eor x22, x19, x22, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x20, ror #5
        eor x26, x19, x26, ror #2
        mov x2, x15
        xar v3.2d, v18.2d, v27.2d, #43
        mov x20, x30
        bic x19, x28, x30, ror #10
        eor x15, x15, x19
        bic x19, x10, x28, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x30, x19, x30, ror #8
        bic x19, x12, x10, ror #4
        eor x28, x19, x28, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x12, ror #62
        eor x10, x19, x10, ror #2
        bic x19, x20, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x12, x19, x12, ror #52
        ldr x20, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x20
        eor x20, x11, x2, ror #3
        eor x20, x20, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x20, x20, x7, ror #14
        eor x20, x20, x15, ror #24
        eor x19, x6, x14, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x27, ror #51
        eor x19, x19, x4, ror #3
        eor x19, x19, x30, ror #22
        mov v30.16b, v1.16b
        str x15, [sp, #104]
        eor x15, x16, x9, ror #24
        eor x15, x15, x5, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x15, x15, x24, ror #8
        eor x15, x15, x28, ror #61
        str x11, [sp, #80]
        eor x11, x3, x17, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x11, x11, x25, ror #38
        eor x11, x11, x22, ror #13
        eor x11, x11, x10, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x7, [sp, #96]
        eor x7, x12, x21, ror #10
        eor x7, x7, x8, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x7, x7, x23, ror #46
        eor x7, x7, x26, ror #61
        str x13, [sp, #88]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x15, x20, ror #40
        eor x6, x13, x6, ror #44
        eor x14, x13, x14, ror #19
        mov v29.16b, v5.16b
        eor x27, x13, x27, ror #31
        eor x4, x13, x4, ror #47
        eor x30, x13, x30, ror #2
        mov v30.16b, v6.16b
        eor x13, x11, x19, ror #46
        eor x9, x13, x9, ror #27
        eor x16, x13, x16, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x5, x13, x5, ror #27
        eor x24, x13, x24, ror #11
        eor x28, x13, x28
        eor x13, x19, x7, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x15, x7, ror #8
        eor x17, x19, x17, ror #42
        eor x25, x19, x25, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x3, x19, x3, ror #62
        eor x22, x19, x22, ror #11
        eor x10, x19, x10, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x15, x20, x11, ror #24
        eor x21, x15, x21, ror #45
        eor x8, x15, x8, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x23, x15, x23, ror #17
        eor x26, x15, x26, ror #32
        eor x12, x15, x12, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x7, [sp, #80]
        eor x7, x13, x7, ror #61
        mov v30.16b, v11.16b
        ldr x15, [sp, #88]
        eor x15, x13, x15, ror #61
        ldr x11, [sp, #96]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x11, x13, x11, ror #11
        ldr x20, [sp, #104]
        eor x20, x13, x20, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x14
        str x6, [sp, #104]
        bic x6, x5, x14, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x6, ror #40
        bic x6, x22, x5, ror #39
        eor x14, x6, x14, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x6, x12, x22, ror #19
        eor x5, x6, x5, ror #58
        bic x6, x13, x12, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x22, x6, x22, ror #1
        bic x6, x19, x13, ror #23
        eor x12, x6, x12, ror #5
        mov v29.16b, v15.16b
        mov x19, x17
        mov x13, x8
        bic x6, x15, x8, ror #43
        mov v30.16b, v16.16b
        eor x17, x6, x17, ror #61
        bic x6, x4, x15, ror #21
        eor x8, x8, x6
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x6, x28, x4, ror #18
        eor x15, x6, x15, ror #39
        bic x6, x19, x28, ror #28
        eor x4, x6, x4, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x6, x13, x19, ror #18
        eor x28, x6, x28, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x6, x16
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x3, x16, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x26, x3, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x16, x2, x16, ror #25
        bic x2, x20, x26, ror #6
        eor x3, x2, x3, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x20, ror #26
        eor x26, x2, x26, ror #32
        bic x2, x6, x19, ror #7
        mov v30.16b, v21.16b
        eor x20, x2, x20, ror #33
        mov x6, x21
        mov x19, x7
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x27, x7, ror #17
        eor x21, x2, x21, ror #22
        bic x2, x24, x27, ror #7
        eor x7, x2, x7, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x10, x24, ror #38
        eor x27, x2, x27, ror #45
        bic x2, x6, x10, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x24, x2, x24, ror #35
        bic x2, x19, x6, ror #5
        eor x10, x2, x10, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x9
        mov x6, x25
        bic x2, x23, x25, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x9, x9, x2
        bic x2, x11, x23, ror #62
        eor x25, x2, x25, ror #8
        ldr d31, [x1, #32]
        bic x2, x30, x11, ror #4
        eor x23, x2, x23, ror #2
        bic x2, x19, x30, ror #62
        dup v31.2d, v31.d[0]
        eor x11, x2, x11, ror #2
        bic x2, x6, x19, ror #54
        eor x30, x2, x30, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x6, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x6
        eor x6, x17, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x6, x6, x13
        eor x6, x6, x21, ror #14
        eor x6, x6, x9, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x14, x8, ror #39
        eor x2, x2, x16, ror #51
        eor x2, x2, x7, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x25, ror #22
        str x9, [sp, #104]
        eor x9, x15, x5, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x9, x9, x3, ror #24
        eor x9, x9, x27, ror #8
        eor x9, x9, x23, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x17, [sp, #96]
        eor x17, x26, x22, ror #44
        eor x17, x17, x4, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x17, x17, x24, ror #13
        eor x17, x17, x11, ror #1
        str x21, [sp, #88]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x21, x30, x12, ror #10
        eor x21, x21, x28, ror #9
        eor x21, x21, x20, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x21, x21, x10, ror #61
        str x13, [sp, #80]
        eor x13, x9, x6, ror #40
        eor x14, x13, x14, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x8, x13, x8, ror #19
        eor x16, x13, x16, ror #31
        eor x7, x13, x7, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x25, x13, x25, ror #2
        eor x13, x17, x2, ror #46
        eor x5, x13, x5, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x15, x13, x15, ror #3
        eor x3, x13, x3, ror #27
        eor x27, x13, x27, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x23, x13, x23
        eor x13, x2, x21, ror #31
        eor x2, x9, x21, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x22, x2, x22, ror #42
        eor x4, x2, x4, ror #36
        eor x26, x2, x26, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x24, x2, x24, ror #11
        eor x11, x2, x11, ror #63
        eor x9, x6, x17, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x12, x9, x12, ror #45
        eor x28, x9, x28, ror #44
        eor x20, x9, x20, ror #17
        eor x10, x9, x10, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x30, x9, x30, ror #35
        eor x19, x13, x19
        ldr x21, [sp, #96]
        mov v25.16b, v1.16b
        eor x21, x13, x21, ror #61
        ldr x9, [sp, #80]
        eor x9, x13, x9, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x17, [sp, #88]
        eor x17, x13, x17, ror #11
        ldr x6, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x6, x13, x6, ror #21
        mov x13, x19
        mov x2, x8
        xar v9.2d, v22.2d, v31.2d, #3
        str x14, [sp, #104]
        bic x14, x3, x8, ror #1
        eor x19, x19, x14, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x14, x24, x3, ror #39
        eor x8, x14, x8, ror #40
        bic x14, x30, x24, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x3, x14, x3, ror #58
        bic x14, x13, x30, ror #46
        eor x24, x14, x24, ror #1
        bic x14, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x30, x14, x30, ror #5
        mov x2, x22
        mov x13, x28
        xar v2.2d, v12.2d, v31.2d, #21
        bic x14, x9, x28, ror #43
        eor x22, x14, x22, ror #61
        bic x14, x7, x9, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x28, x28, x14
        bic x14, x23, x7, ror #18
        eor x9, x14, x9, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x14, x2, x23, ror #28
        eor x7, x14, x7, ror #46
        bic x14, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x23, x14, x23, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x14, x15
        str x19, [sp, #104]
        bic x19, x26, x15, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x10, x26, ror #9
        eor x15, x19, x15, ror #25
        bic x19, x6, x10, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x26, x19, x26, ror #15
        bic x19, x2, x6, ror #26
        eor x10, x19, x10, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x14, x2, ror #7
        eor x6, x19, x6, ror #33
        mov x14, x12
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x21
        bic x19, x16, x21, ror #17
        eor x12, x19, x12, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x27, x16, ror #7
        eor x21, x19, x21, ror #24
        bic x19, x11, x27, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x16, x19, x16, ror #45
        bic x19, x14, x11, ror #61
        eor x27, x19, x27, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x14, ror #5
        eor x11, x19, x11, ror #2
        mov x2, x5
        xar v3.2d, v18.2d, v27.2d, #43
        mov x14, x4
        bic x19, x20, x4, ror #10
        eor x5, x5, x19
        bic x19, x17, x20, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x4, x19, x4, ror #8
        bic x19, x25, x17, ror #4
        eor x20, x19, x20, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x25, ror #62
        eor x17, x19, x17, ror #2
        bic x19, x14, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x25, x19, x25, ror #52
        ldr x14, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x14
        eor x14, x22, x2, ror #3
        eor x14, x14, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x14, x14, x12, ror #14
        eor x14, x14, x5, ror #24
        eor x19, x8, x28, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x15, ror #51
        eor x19, x19, x21, ror #3
        eor x19, x19, x4, ror #22
        mov v30.16b, v1.16b
        str x5, [sp, #104]
        eor x5, x9, x3, ror #24
        eor x5, x5, x26, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x5, x5, x16, ror #8
        eor x5, x5, x20, ror #61
        str x22, [sp, #88]
        eor x22, x10, x24, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x22, x22, x7, ror #38
        eor x22, x22, x27, ror #13
        eor x22, x22, x17, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x12, [sp, #80]
        eor x12, x25, x30, ror #10
        eor x12, x12, x23, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x12, x12, x6, ror #46
        eor x12, x12, x11, ror #61
        str x13, [sp, #96]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x5, x14, ror #40
        eor x8, x13, x8, ror #44
        eor x28, x13, x28, ror #19
        mov v29.16b, v5.16b
        eor x15, x13, x15, ror #31
        eor x21, x13, x21, ror #47
        eor x4, x13, x4, ror #2
        mov v30.16b, v6.16b
        eor x13, x22, x19, ror #46
        eor x3, x13, x3, ror #27
        eor x9, x13, x9, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x26, x13, x26, ror #27
        eor x16, x13, x16, ror #11
        eor x20, x13, x20
        eor x13, x19, x12, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x5, x12, ror #8
        eor x24, x19, x24, ror #42
        eor x7, x19, x7, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x10, x19, x10, ror #62
        eor x27, x19, x27, ror #11
        eor x17, x19, x17, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x5, x14, x22, ror #24
        eor x30, x5, x30, ror #45
        eor x23, x5, x23, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x6, x5, x6, ror #17
        eor x11, x5, x11, ror #32
        eor x25, x5, x25, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x12, [sp, #88]
        eor x12, x13, x12, ror #61
        mov v30.16b, v11.16b
        ldr x5, [sp, #96]
        eor x5, x13, x5, ror #61
        ldr x22, [sp, #80]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x22, x13, x22, ror #11
        ldr x14, [sp, #104]
        eor x14, x13, x14, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x28
        str x8, [sp, #104]
        bic x8, x26, x28, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x8, ror #40
        bic x8, x27, x26, ror #39
        eor x28, x8, x28, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x8, x25, x27, ror #19
        eor x26, x8, x26, ror #58
        bic x8, x13, x25, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x27, x8, x27, ror #1
        bic x8, x19, x13, ror #23
        eor x25, x8, x25, ror #5
        mov v29.16b, v15.16b
        mov x19, x24
        mov x13, x23
        bic x8, x5, x23, ror #43
        mov v30.16b, v16.16b
        eor x24, x8, x24, ror #61
        bic x8, x21, x5, ror #21
        eor x23, x23, x8
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x8, x20, x21, ror #18
        eor x5, x8, x5, ror #39
        bic x8, x19, x20, ror #28
        eor x21, x8, x21, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x8, x13, x19, ror #18
        eor x20, x8, x20, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x8, x9
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x10, x9, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x11, x10, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x9, x2, x9, ror #25
        bic x2, x14, x11, ror #6
        eor x10, x2, x10, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x14, ror #26
        eor x11, x2, x11, ror #32
        bic x2, x8, x19, ror #7
        mov v30.16b, v21.16b
        eor x14, x2, x14, ror #33
        mov x8, x30
        mov x19, x12
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x15, x12, ror #17
        eor x30, x2, x30, ror #22
        bic x2, x16, x15, ror #7
        eor x12, x2, x12, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x17, x16, ror #38
        eor x15, x2, x15, ror #45
        bic x2, x8, x17, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x16, x2, x16, ror #35
        bic x2, x19, x8, ror #5
        eor x17, x2, x17, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x3
        mov x8, x7
        bic x2, x6, x7, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x3, x3, x2
        bic x2, x22, x6, ror #62
        eor x7, x2, x7, ror #8
        ldr d31, [x1, #24]
        bic x2, x4, x22, ror #4
        eor x6, x2, x6, ror #2
        bic x2, x19, x4, ror #62
        dup v31.2d, v31.d[0]
        eor x22, x2, x22, ror #2
        bic x2, x8, x19, ror #54
        eor x4, x2, x4, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x8, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x8
        eor x8, x24, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x8, x8, x13
        eor x8, x8, x30, ror #14
        eor x8, x8, x3, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x28, x23, ror #39
        eor x2, x2, x9, ror #51
        eor x2, x2, x12, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x7, ror #22
        str x3, [sp, #104]
        eor x3, x5, x26, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x3, x3, x10, ror #24
        eor x3, x3, x15, ror #8
        eor x3, x3, x6, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x24, [sp, #80]
        eor x24, x11, x27, ror #44
        eor x24, x24, x21, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x24, x24, x16, ror #13
        eor x24, x24, x22, ror #1
        str x30, [sp, #96]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x30, x4, x25, ror #10
        eor x30, x30, x20, ror #9
        eor x30, x30, x14, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x30, x30, x17, ror #61
        str x13, [sp, #88]
        eor x13, x3, x8, ror #40
        eor x28, x13, x28, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x23, x13, x23, ror #19
        eor x9, x13, x9, ror #31
        eor x12, x13, x12, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x7, x13, x7, ror #2
        eor x13, x24, x2, ror #46
        eor x26, x13, x26, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x5, x13, x5, ror #3
        eor x10, x13, x10, ror #27
        eor x15, x13, x15, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x6, x13, x6
        eor x13, x2, x30, ror #31
        eor x2, x3, x30, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x27, x2, x27, ror #42
        eor x21, x2, x21, ror #36
        eor x11, x2, x11, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x16, x2, x16, ror #11
        eor x22, x2, x22, ror #63
        eor x3, x8, x24, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x25, x3, x25, ror #45
        eor x20, x3, x20, ror #44
        eor x14, x3, x14, ror #17
        eor x17, x3, x17, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x4, x3, x4, ror #35
        eor x19, x13, x19
        ldr x30, [sp, #80]
        mov v25.16b, v1.16b
        eor x30, x13, x30, ror #61
        ldr x3, [sp, #88]
        eor x3, x13, x3, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x24, [sp, #96]
        eor x24, x13, x24, ror #11
        ldr x8, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x8, x13, x8, ror #21
        mov x13, x19
        mov x2, x23
        xar v9.2d, v22.2d, v31.2d, #3
        str x28, [sp, #104]
        bic x28, x10, x23, ror #1
        eor x19, x19, x28, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x28, x16, x10, ror #39
        eor x23, x28, x23, ror #40
        bic x28, x4, x16, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x10, x28, x10, ror #58
        bic x28, x13, x4, ror #46
        eor x16, x28, x16, ror #1
        bic x28, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x4, x28, x4, ror #5
        mov x2, x27
        mov x13, x20
        xar v2.2d, v12.2d, v31.2d, #21
        bic x28, x3, x20, ror #43
        eor x27, x28, x27, ror #61
        bic x28, x12, x3, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x20, x20, x28
        bic x28, x6, x12, ror #18
        eor x3, x28, x3, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x28, x2, x6, ror #28
        eor x12, x28, x12, ror #46
        bic x28, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x6, x28, x6, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x28, x5
        str x19, [sp, #104]
        bic x19, x11, x5, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x17, x11, ror #9
        eor x5, x19, x5, ror #25
        bic x19, x8, x17, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x11, x19, x11, ror #15
        bic x19, x2, x8, ror #26
        eor x17, x19, x17, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x28, x2, ror #7
        eor x8, x19, x8, ror #33
        mov x28, x25
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x30
        bic x19, x9, x30, ror #17
        eor x25, x19, x25, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x15, x9, ror #7
        eor x30, x19, x30, ror #24
        bic x19, x22, x15, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x9, x19, x9, ror #45
        bic x19, x28, x22, ror #61
        eor x15, x19, x15, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x28, ror #5
        eor x22, x19, x22, ror #2
        mov x2, x26
        xar v3.2d, v18.2d, v27.2d, #43
        mov x28, x21
        bic x19, x14, x21, ror #10
        eor x26, x26, x19
        bic x19, x24, x14, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x21, x19, x21, ror #8
        bic x19, x7, x24, ror #4
        eor x14, x19, x14, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x7, ror #62
        eor x24, x19, x24, ror #2
        bic x19, x28, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x7, x19, x7, ror #52
        ldr x28, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x28
        eor x28, x27, x2, ror #3
        eor x28, x28, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x28, x28, x25, ror #14
        eor x28, x28, x26, ror #24
        eor x19, x23, x20, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x5, ror #51
        eor x19, x19, x30, ror #3
        eor x19, x19, x21, ror #22
        mov v30.16b, v1.16b
        str x26, [sp, #104]
        eor x26, x3, x10, ror #24
        eor x26, x26, x11, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x26, x26, x9, ror #8
        eor x26, x26, x14, ror #61
        str x27, [sp, #96]
        eor x27, x17, x16, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x27, x27, x12, ror #38
        eor x27, x27, x15, ror #13
        eor x27, x27, x24, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x25, [sp, #88]
        eor x25, x7, x4, ror #10
        eor x25, x25, x6, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x25, x25, x8, ror #46
        eor x25, x25, x22, ror #61
        str x13, [sp, #80]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x26, x28, ror #40
        eor x23, x13, x23, ror #44
        eor x20, x13, x20, ror #19
        mov v29.16b, v5.16b
        eor x5, x13, x5, ror #31
        eor x30, x13, x30, ror #47
        eor x21, x13, x21, ror #2
        mov v30.16b, v6.16b
        eor x13, x27, x19, ror #46
        eor x10, x13, x10, ror #27
        eor x3, x13, x3, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x11, x13, x11, ror #27
        eor x9, x13, x9, ror #11
        eor x14, x13, x14
        eor x13, x19, x25, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x26, x25, ror #8
        eor x16, x19, x16, ror #42
        eor x12, x19, x12, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x17, x19, x17, ror #62
        eor x15, x19, x15, ror #11
        eor x24, x19, x24, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x26, x28, x27, ror #24
        eor x4, x26, x4, ror #45
        eor x6, x26, x6, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x8, x26, x8, ror #17
        eor x22, x26, x22, ror #32
        eor x7, x26, x7, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x25, [sp, #96]
        eor x25, x13, x25, ror #61
        mov v30.16b, v11.16b
        ldr x26, [sp, #80]
        eor x26, x13, x26, ror #61
        ldr x27, [sp, #88]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x27, x13, x27, ror #11
        ldr x28, [sp, #104]
        eor x28, x13, x28, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x20
        str x23, [sp, #104]
        bic x23, x11, x20, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x23, ror #40
        bic x23, x15, x11, ror #39
        eor x20, x23, x20, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x23, x7, x15, ror #19
        eor x11, x23, x11, ror #58
        bic x23, x13, x7, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x15, x23, x15, ror #1
        bic x23, x19, x13, ror #23
        eor x7, x23, x7, ror #5
        mov v29.16b, v15.16b
        mov x19, x16
        mov x13, x6
        bic x23, x26, x6, ror #43
        mov v30.16b, v16.16b
        eor x16, x23, x16, ror #61
        bic x23, x30, x26, ror #21
        eor x6, x6, x23
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x23, x14, x30, ror #18
        eor x26, x23, x26, ror #39
        bic x23, x19, x14, ror #28
        eor x30, x23, x30, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x23, x13, x19, ror #18
        eor x14, x23, x14, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x23, x3
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x17, x3, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x22, x17, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x3, x2, x3, ror #25
        bic x2, x28, x22, ror #6
        eor x17, x2, x17, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x28, ror #26
        eor x22, x2, x22, ror #32
        bic x2, x23, x19, ror #7
        mov v30.16b, v21.16b
        eor x28, x2, x28, ror #33
        mov x23, x4
        mov x19, x25
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x5, x25, ror #17
        eor x4, x2, x4, ror #22
        bic x2, x9, x5, ror #7
        eor x25, x2, x25, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x24, x9, ror #38
        eor x5, x2, x5, ror #45
        bic x2, x23, x24, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x9, x2, x9, ror #35
        bic x2, x19, x23, ror #5
        eor x24, x2, x24, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x10
        mov x23, x12
        bic x2, x8, x12, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x10, x10, x2
        bic x2, x27, x8, ror #62
        eor x12, x2, x12, ror #8
        ldr d31, [x1, #16]
        bic x2, x21, x27, ror #4
        eor x8, x2, x8, ror #2
        bic x2, x19, x21, ror #62
        dup v31.2d, v31.d[0]
        eor x27, x2, x27, ror #2
        bic x2, x23, x19, ror #54
        eor x21, x2, x21, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x23, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x23
        eor x23, x16, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x23, x23, x13
        eor x23, x23, x4, ror #14
        eor x23, x23, x10, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x20, x6, ror #39
        eor x2, x2, x3, ror #51
        eor x2, x2, x25, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x12, ror #22
        str x10, [sp, #104]
        eor x10, x26, x11, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x10, x10, x17, ror #24
        eor x10, x10, x5, ror #8
        eor x10, x10, x8, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x16, [sp, #88]
        eor x16, x22, x15, ror #44
        eor x16, x16, x30, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x16, x16, x9, ror #13
        eor x16, x16, x27, ror #1
        str x4, [sp, #80]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x4, x21, x7, ror #10
        eor x4, x4, x14, ror #9
        eor x4, x4, x28, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x4, x4, x24, ror #61
        str x13, [sp, #96]
        eor x13, x10, x23, ror #40
        eor x20, x13, x20, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x6, x13, x6, ror #19
        eor x3, x13, x3, ror #31
        eor x25, x13, x25, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x12, x13, x12, ror #2
        eor x13, x16, x2, ror #46
        eor x11, x13, x11, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x26, x13, x26, ror #3
        eor x17, x13, x17, ror #27
        eor x5, x13, x5, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x8, x13, x8
        eor x13, x2, x4, ror #31
        eor x2, x10, x4, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x15, x2, x15, ror #42
        eor x30, x2, x30, ror #36
        eor x22, x2, x22, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x9, x2, x9, ror #11
        eor x27, x2, x27, ror #63
        eor x10, x23, x16, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x7, x10, x7, ror #45
        eor x14, x10, x14, ror #44
        eor x28, x10, x28, ror #17
        eor x24, x10, x24, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x21, x10, x21, ror #35
        eor x19, x13, x19
        ldr x4, [sp, #88]
        mov v25.16b, v1.16b
        eor x4, x13, x4, ror #61
        ldr x10, [sp, #96]
        eor x10, x13, x10, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x16, [sp, #80]
        eor x16, x13, x16, ror #11
        ldr x23, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x23, x13, x23, ror #21
        mov x13, x19
        mov x2, x6
        xar v9.2d, v22.2d, v31.2d, #3
        str x20, [sp, #104]
        bic x20, x17, x6, ror #1
        eor x19, x19, x20, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x20, x9, x17, ror #39
        eor x6, x20, x6, ror #40
        bic x20, x21, x9, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x17, x20, x17, ror #58
        bic x20, x13, x21, ror #46
        eor x9, x20, x9, ror #1
        bic x20, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x21, x20, x21, ror #5
        mov x2, x15
        mov x13, x14
        xar v2.2d, v12.2d, v31.2d, #21
        bic x20, x10, x14, ror #43
        eor x15, x20, x15, ror #61
        bic x20, x25, x10, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x14, x14, x20
        bic x20, x8, x25, ror #18
        eor x10, x20, x10, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x20, x2, x8, ror #28
        eor x25, x20, x25, ror #46
        bic x20, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x8, x20, x8, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x20, x26
        str x19, [sp, #104]
        bic x19, x22, x26, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x24, x22, ror #9
        eor x26, x19, x26, ror #25
        bic x19, x23, x24, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x22, x19, x22, ror #15
        bic x19, x2, x23, ror #26
        eor x24, x19, x24, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x20, x2, ror #7
        eor x23, x19, x23, ror #33
        mov x20, x7
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x4
        bic x19, x3, x4, ror #17
        eor x7, x19, x7, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x5, x3, ror #7
        eor x4, x19, x4, ror #24
        bic x19, x27, x5, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x3, x19, x3, ror #45
        bic x19, x20, x27, ror #61
        eor x5, x19, x5, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x20, ror #5
        eor x27, x19, x27, ror #2
        mov x2, x11
        xar v3.2d, v18.2d, v27.2d, #43
        mov x20, x30
        bic x19, x28, x30, ror #10
        eor x11, x11, x19
        bic x19, x16, x28, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x30, x19, x30, ror #8
        bic x19, x12, x16, ror #4
        eor x28, x19, x28, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x12, ror #62
        eor x16, x19, x16, ror #2
        bic x19, x20, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x12, x19, x12, ror #52
        ldr x20, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x20
        eor x20, x15, x2, ror #3
        eor x20, x20, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x20, x20, x7, ror #14
        eor x20, x20, x11, ror #24
        eor x19, x6, x14, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x26, ror #51
        eor x19, x19, x4, ror #3
        eor x19, x19, x30, ror #22
        mov v30.16b, v1.16b
        str x11, [sp, #104]
        eor x11, x10, x17, ror #24
        eor x11, x11, x22, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x11, x11, x3, ror #8
        eor x11, x11, x28, ror #61
        str x15, [sp, #80]
        eor x15, x24, x9, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x15, x15, x25, ror #38
        eor x15, x15, x5, ror #13
        eor x15, x15, x16, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x7, [sp, #96]
        eor x7, x12, x21, ror #10
        eor x7, x7, x8, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x7, x7, x23, ror #46
        eor x7, x7, x27, ror #61
        str x13, [sp, #88]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x11, x20, ror #40
        eor x6, x13, x6, ror #44
        eor x14, x13, x14, ror #19
        mov v29.16b, v5.16b
        eor x26, x13, x26, ror #31
        eor x4, x13, x4, ror #47
        eor x30, x13, x30, ror #2
        mov v30.16b, v6.16b
        eor x13, x15, x19, ror #46
        eor x17, x13, x17, ror #27
        eor x10, x13, x10, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x22, x13, x22, ror #27
        eor x3, x13, x3, ror #11
        eor x28, x13, x28
        eor x13, x19, x7, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x11, x7, ror #8
        eor x9, x19, x9, ror #42
        eor x25, x19, x25, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x24, x19, x24, ror #62
        eor x5, x19, x5, ror #11
        eor x16, x19, x16, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x11, x20, x15, ror #24
        eor x21, x11, x21, ror #45
        eor x8, x11, x8, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x23, x11, x23, ror #17
        eor x27, x11, x27, ror #32
        eor x12, x11, x12, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x7, [sp, #80]
        eor x7, x13, x7, ror #61
        mov v30.16b, v11.16b
        ldr x11, [sp, #88]
        eor x11, x13, x11, ror #61
        ldr x15, [sp, #96]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x15, x13, x15, ror #11
        ldr x20, [sp, #104]
        eor x20, x13, x20, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x14
        str x6, [sp, #104]
        bic x6, x22, x14, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x6, ror #40
        bic x6, x5, x22, ror #39
        eor x14, x6, x14, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x6, x12, x5, ror #19
        eor x22, x6, x22, ror #58
        bic x6, x13, x12, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x5, x6, x5, ror #1
        bic x6, x19, x13, ror #23
        eor x12, x6, x12, ror #5
        mov v29.16b, v15.16b
        mov x19, x9
        mov x13, x8
        bic x6, x11, x8, ror #43
        mov v30.16b, v16.16b
        eor x9, x6, x9, ror #61
        bic x6, x4, x11, ror #21
        eor x8, x8, x6
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x6, x28, x4, ror #18
        eor x11, x6, x11, ror #39
        bic x6, x19, x28, ror #28
        eor x4, x6, x4, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x6, x13, x19, ror #18
        eor x28, x6, x28, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x6, x10
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x24, x10, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x27, x24, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x10, x2, x10, ror #25
        bic x2, x20, x27, ror #6
        eor x24, x2, x24, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x20, ror #26
        eor x27, x2, x27, ror #32
        bic x2, x6, x19, ror #7
        mov v30.16b, v21.16b
        eor x20, x2, x20, ror #33
        mov x6, x21
        mov x19, x7
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x26, x7, ror #17
        eor x21, x2, x21, ror #22
        bic x2, x3, x26, ror #7
        eor x7, x2, x7, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x16, x3, ror #38
        eor x26, x2, x26, ror #45
        bic x2, x6, x16, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x3, x2, x3, ror #35
        bic x2, x19, x6, ror #5
        eor x16, x2, x16, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x17
        mov x6, x25
        bic x2, x23, x25, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x17, x17, x2
        bic x2, x15, x23, ror #62
        eor x25, x2, x25, ror #8
        ldr d31, [x1, #8]
        bic x2, x30, x15, ror #4
        eor x23, x2, x23, ror #2
        bic x2, x19, x30, ror #62
        dup v31.2d, v31.d[0]
        eor x15, x2, x15, ror #2
        bic x2, x6, x19, ror #54
        eor x30, x2, x30, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x6, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x6
        eor x6, x9, x19, ror #3
        eor3 v25.16b, v0.16b, v5.16b, v10.16b
        eor x6, x6, x13
        eor x6, x6, x21, ror #14
        eor x6, x6, x17, ror #24
        eor3 v25.16b, v25.16b, v15.16b, v20.16b
        eor x2, x14, x8, ror #39
        eor x2, x2, x10, ror #51
        eor x2, x2, x7, ror #3
        eor3 v26.16b, v1.16b, v6.16b, v11.16b
        eor x2, x2, x25, ror #22
        str x17, [sp, #104]
        eor x17, x11, x22, ror #24
        eor3 v26.16b, v26.16b, v16.16b, v21.16b
        eor x17, x17, x24, ror #24
        eor x17, x17, x26, ror #8
        eor x17, x17, x23, ror #61
        eor3 v27.16b, v2.16b, v7.16b, v12.16b
        str x9, [sp, #96]
        eor x9, x27, x5, ror #44
        eor x9, x9, x4, ror #38
        eor3 v27.16b, v27.16b, v17.16b, v22.16b
        eor x9, x9, x3, ror #13
        eor x9, x9, x15, ror #1
        str x21, [sp, #88]
        eor3 v28.16b, v3.16b, v8.16b, v13.16b
        eor x21, x30, x12, ror #10
        eor x21, x21, x28, ror #9
        eor x21, x21, x20, ror #46
        eor3 v28.16b, v28.16b, v18.16b, v23.16b
        eor x21, x21, x16, ror #61
        str x13, [sp, #80]
        eor x13, x17, x6, ror #40
        eor x14, x13, x14, ror #44
        eor3 v29.16b, v4.16b, v9.16b, v14.16b
        eor x8, x13, x8, ror #19
        eor x10, x13, x10, ror #31
        eor x7, x13, x7, ror #47
        eor3 v29.16b, v29.16b, v19.16b, v24.16b
        eor x25, x13, x25, ror #2
        eor x13, x9, x2, ror #46
        eor x22, x13, x22, ror #27
        rax1 v30.2d, v29.2d, v26.2d
        eor x11, x13, x11, ror #3
        eor x24, x13, x24, ror #27
        eor x26, x13, x26, ror #11
        rax1 v31.2d, v26.2d, v28.2d
        eor x23, x13, x23
        eor x13, x2, x21, ror #31
        eor x2, x17, x21, ror #8
        rax1 v26.2d, v25.2d, v27.2d
        eor x5, x2, x5, ror #42
        eor x4, x2, x4, ror #36
        eor x27, x2, x27, ror #62
        rax1 v27.2d, v27.2d, v29.2d
        eor x3, x2, x3, ror #11
        eor x15, x2, x15, ror #63
        eor x17, x6, x9, ror #24
        rax1 v28.2d, v28.2d, v25.2d
        eor x12, x17, x12, ror #45
        eor x28, x17, x28, ror #44
        eor x20, x17, x20, ror #17
        eor x16, x17, x16, ror #32
        eor v0.16b, v0.16b, v30.16b
        eor x30, x17, x30, ror #35
        eor x19, x13, x19
        ldr x21, [sp, #96]
        mov v25.16b, v1.16b
        eor x21, x13, x21, ror #61
        ldr x17, [sp, #80]
        eor x17, x13, x17, ror #61
        xar v1.2d, v6.2d, v26.2d, #20
        ldr x9, [sp, #88]
        eor x9, x13, x9, ror #11
        ldr x6, [sp, #104]
        xar v6.2d, v9.2d, v28.2d, #44
        eor x6, x13, x6, ror #21
        mov x13, x19
        mov x2, x8
        xar v9.2d, v22.2d, v31.2d, #3
        str x14, [sp, #104]
        bic x14, x24, x8, ror #1
        eor x19, x19, x14, ror #40
        xar v22.2d, v14.2d, v28.2d, #25
        bic x14, x3, x24, ror #39
        eor x8, x14, x8, ror #40
        bic x14, x30, x3, ror #19
        xar v14.2d, v20.2d, v30.2d, #46
        eor x24, x14, x24, ror #58
        bic x14, x13, x30, ror #46
        eor x3, x14, x3, ror #1
        bic x14, x2, x13, ror #23
        xar v20.2d, v2.2d, v31.2d, #2
        eor x30, x14, x30, ror #5
        mov x2, x5
        mov x13, x28
        xar v2.2d, v12.2d, v31.2d, #21
        bic x14, x17, x28, ror #43
        eor x5, x14, x5, ror #61
        bic x14, x7, x17, ror #21
        xar v12.2d, v13.2d, v27.2d, #39
        eor x28, x28, x14
        bic x14, x23, x7, ror #18
        eor x17, x14, x17, ror #39
        xar v13.2d, v19.2d, v28.2d, #56
        bic x14, x2, x23, ror #28
        eor x7, x14, x7, ror #46
        bic x14, x13, x2, ror #18
        xar v19.2d, v23.2d, v27.2d, #8
        eor x23, x14, x23, ror #46
        ldr x13, [sp, #104]
        mov x2, x13
        xar v23.2d, v15.2d, v30.2d, #23
        mov x14, x11
        str x19, [sp, #104]
        bic x19, x27, x11, ror #16
        xar v15.2d, v4.2d, v28.2d, #37
        eor x13, x19, x13, ror #23
        bic x19, x16, x27, ror #9
        eor x11, x19, x11, ror #25
        bic x19, x6, x16, ror #6
        xar v4.2d, v24.2d, v28.2d, #50
        eor x27, x19, x27, ror #15
        bic x19, x2, x6, ror #26
        eor x16, x19, x16, ror #32
        xar v24.2d, v21.2d, v26.2d, #62
        bic x19, x14, x2, ror #7
        eor x6, x19, x6, ror #33
        mov x14, x12
        xar v21.2d, v8.2d, v27.2d, #9
        mov x2, x21
        bic x19, x10, x21, ror #17
        eor x12, x19, x12, ror #22
        xar v8.2d, v16.2d, v26.2d, #19
        bic x19, x26, x10, ror #7
        eor x21, x19, x21, ror #24
        bic x19, x15, x26, ror #38
        xar v16.2d, v5.2d, v30.2d, #28
        eor x10, x19, x10, ror #45
        bic x19, x14, x15, ror #61
        eor x26, x19, x26, ror #35
        xar v5.2d, v3.2d, v27.2d, #36
        bic x19, x2, x14, ror #5
        eor x15, x19, x15, ror #2
        mov x2, x22
        xar v3.2d, v18.2d, v27.2d, #43
        mov x14, x4
        bic x19, x20, x4, ror #10
        eor x22, x22, x19
        bic x19, x9, x20, ror #62
        xar v18.2d, v17.2d, v31.2d, #49
        eor x4, x19, x4, ror #8
        bic x19, x25, x9, ror #4
        eor x20, x19, x20, ror #2
        xar v17.2d, v11.2d, v26.2d, #54
        bic x19, x2, x25, ror #62
        eor x9, x19, x9, ror #2
        bic x19, x14, x2, ror #54
        xar v11.2d, v7.2d, v31.2d, #58
        eor x25, x19, x25, ror #52
        ldr x14, [x1], #8
        ldr x2, [sp, #104]
        xar v7.2d, v10.2d, v30.2d, #61
        eor x2, x2, x14
        eor x14, x5, x2, ror #3
        eor x14, x14, x13
        xar v10.2d, v25.2d, v26.2d, #63
        eor x14, x14, x12, ror #14
        eor x14, x14, x22, ror #24
        eor x19, x8, x28, ror #39
        mov v29.16b, v0.16b
        eor x19, x19, x11, ror #51
        eor x19, x19, x21, ror #3
        eor x19, x19, x4, ror #22
        mov v30.16b, v1.16b
        str x22, [sp, #104]
        eor x22, x17, x24, ror #24
        eor x22, x22, x27, ror #24
        bcax v0.16b, v0.16b, v2.16b, v1.16b
        eor x22, x22, x10, ror #8
        eor x22, x22, x20, ror #61
        str x5, [sp, #88]
        eor x5, x16, x3, ror #44
        bcax v1.16b, v1.16b, v3.16b, v2.16b
        eor x5, x5, x7, ror #38
        eor x5, x5, x26, ror #13
        eor x5, x5, x9, ror #1
        bcax v2.16b, v2.16b, v4.16b, v3.16b
        str x12, [sp, #80]
        eor x12, x25, x30, ror #10
        eor x12, x12, x23, ror #9
        bcax v3.16b, v3.16b, v29.16b, v4.16b
        eor x12, x12, x6, ror #46
        eor x12, x12, x15, ror #61
        str x13, [sp, #96]
        bcax v4.16b, v4.16b, v30.16b, v29.16b
        eor x13, x22, x14, ror #40
        eor x8, x13, x8, ror #44
        eor x28, x13, x28, ror #19
        mov v29.16b, v5.16b
        eor x11, x13, x11, ror #31
        eor x21, x13, x21, ror #47
        eor x4, x13, x4, ror #2
        mov v30.16b, v6.16b
        eor x13, x5, x19, ror #46
        eor x24, x13, x24, ror #27
        eor x17, x13, x17, ror #3
        bcax v5.16b, v5.16b, v7.16b, v6.16b
        eor x27, x13, x27, ror #27
        eor x10, x13, x10, ror #11
        eor x20, x13, x20
        eor x13, x19, x12, ror #31
        bcax v6.16b, v6.16b, v8.16b, v7.16b
        eor x19, x22, x12, ror #8
        eor x3, x19, x3, ror #42
        eor x7, x19, x7, ror #36
        bcax v7.16b, v7.16b, v9.16b, v8.16b
        eor x16, x19, x16, ror #62
        eor x26, x19, x26, ror #11
        eor x9, x19, x9, ror #63
        bcax v8.16b, v8.16b, v29.16b, v9.16b
        eor x22, x14, x5, ror #24
        eor x30, x22, x30, ror #45
        eor x23, x22, x23, ror #44
        bcax v9.16b, v9.16b, v30.16b, v29.16b
        eor x6, x22, x6, ror #17
        eor x15, x22, x15, ror #32
        eor x25, x22, x25, ror #35
        mov v29.16b, v10.16b
        eor x2, x13, x2
        ldr x12, [sp, #88]
        eor x12, x13, x12, ror #61
        mov v30.16b, v11.16b
        ldr x22, [sp, #96]
        eor x22, x13, x22, ror #61
        ldr x5, [sp, #80]
        bcax v10.16b, v10.16b, v12.16b, v11.16b
        eor x5, x13, x5, ror #11
        ldr x14, [sp, #104]
        eor x14, x13, x14, ror #21
        mov x13, x2
        bcax v11.16b, v11.16b, v13.16b, v12.16b
        mov x19, x28
        str x8, [sp, #104]
        bic x8, x27, x28, ror #1
        bcax v12.16b, v12.16b, v14.16b, v13.16b
        eor x2, x2, x8, ror #40
        bic x8, x26, x27, ror #39
        eor x28, x8, x28, ror #40
        bcax v13.16b, v13.16b, v29.16b, v14.16b
        bic x8, x25, x26, ror #19
        eor x27, x8, x27, ror #58
        bic x8, x13, x25, ror #46
        bcax v14.16b, v14.16b, v30.16b, v29.16b
        eor x26, x8, x26, ror #1
        bic x8, x19, x13, ror #23
        eor x25, x8, x25, ror #5
        mov v29.16b, v15.16b
        mov x19, x3
        mov x13, x23
        bic x8, x22, x23, ror #43
        mov v30.16b, v16.16b
        eor x3, x8, x3, ror #61
        bic x8, x21, x22, ror #21
        eor x23, x23, x8
        bcax v15.16b, v15.16b, v17.16b, v16.16b
        bic x8, x20, x21, ror #18
        eor x22, x8, x22, ror #39
        bic x8, x19, x20, ror #28
        eor x21, x8, x21, ror #46
        bcax v16.16b, v16.16b, v18.16b, v17.16b
        bic x8, x13, x19, ror #18
        eor x20, x8, x20, ror #46
        ldr x13, [sp, #104]
        bcax v17.16b, v17.16b, v19.16b, v18.16b
        mov x19, x13
        mov x8, x17
        str x2, [sp, #104]
        bcax v18.16b, v18.16b, v29.16b, v19.16b
        bic x2, x16, x17, ror #16
        eor x13, x2, x13, ror #23
        bic x2, x15, x16, ror #9
        bcax v19.16b, v19.16b, v30.16b, v29.16b
        eor x17, x2, x17, ror #25
        bic x2, x14, x15, ror #6
        eor x16, x2, x16, ror #15
        mov v29.16b, v20.16b
        bic x2, x19, x14, ror #26
        eor x15, x2, x15, ror #32
        bic x2, x8, x19, ror #7
        mov v30.16b, v21.16b
        eor x14, x2, x14, ror #33
        mov x8, x30
        mov x19, x12
        bcax v20.16b, v20.16b, v22.16b, v21.16b
        bic x2, x11, x12, ror #17
        eor x30, x2, x30, ror #22
        bic x2, x10, x11, ror #7
        eor x12, x2, x12, ror #24
        bcax v21.16b, v21.16b, v23.16b, v22.16b
        bic x2, x9, x10, ror #38
        eor x11, x2, x11, ror #45
        bic x2, x8, x9, ror #61
        bcax v22.16b, v22.16b, v24.16b, v23.16b
        eor x10, x2, x10, ror #35
        bic x2, x19, x8, ror #5
        eor x9, x2, x9, ror #2
        bcax v23.16b, v23.16b, v29.16b, v24.16b
        mov x19, x24
        mov x8, x7
        bic x2, x6, x7, ror #10
        bcax v24.16b, v24.16b, v30.16b, v29.16b
        eor x24, x24, x2
        bic x2, x5, x6, ror #62
        eor x7, x2, x7, ror #8
        ldr d31, [x1, #0]
        bic x2, x4, x5, ror #4
        eor x6, x2, x6, ror #2
        bic x2, x19, x4, ror #62
        dup v31.2d, v31.d[0]
        eor x5, x2, x5, ror #2
        bic x2, x8, x19, ror #54
        eor x4, x2, x4, ror #52
        eor v0.16b, v0.16b, v31.16b
        ldr x8, [x1], #8
        ldr x19, [sp, #104]
        eor x19, x19, x8
        str x19, [x0, #600]
        ror x28, x28, #1
        str x28, [x0, #608]
        ror x27, x27, #46
        str x27, [x0, #616]
        str x26, [x0, #624]
        ror x25, x25, #41
        str x25, [x0, #632]
        ror x3, x3, #61
        str x3, [x0, #640]
        ror x23, x23, #40
        str x23, [x0, #648]
        ror x22, x22, #22
        str x22, [x0, #656]
        ror x21, x21, #58
        str x21, [x0, #664]
        ror x20, x20, #40
        str x20, [x0, #672]
        ror x13, x13, #61
        str x13, [x0, #680]
        ror x17, x17, #52
        str x17, [x0, #688]
        ror x16, x16, #46
        str x16, [x0, #696]
        ror x15, x15, #20
        str x15, [x0, #704]
        ror x14, x14, #13
        str x14, [x0, #712]
        ror x30, x30, #11
        str x30, [x0, #720]
        ror x12, x12, #4
        str x12, [x0, #728]
        ror x11, x11, #30
        str x11, [x0, #736]
        ror x10, x10, #33
        str x10, [x0, #744]
        ror x9, x9, #28
        str x9, [x0, #752]
        ror x24, x24, #21
        str x24, [x0, #760]
        ror x7, x7, #23
        str x7, [x0, #768]
        ror x6, x6, #19
        str x6, [x0, #776]
        ror x5, x5, #21
        str x5, [x0, #784]
        ror x4, x4, #31
        str x4, [x0, #792]
        add x2, x0, #200
        trn1 v30.2d, v0.2d, v1.2d
        trn2 v31.2d, v0.2d, v1.2d
        str q30, [x0, #0]
        str q31, [x2, #0]
        trn1 v30.2d, v2.2d, v3.2d
        trn2 v31.2d, v2.2d, v3.2d
        str q30, [x0, #16]
        str q31, [x2, #16]
        trn1 v30.2d, v4.2d, v5.2d
        trn2 v31.2d, v4.2d, v5.2d
        str q30, [x0, #32]
        str q31, [x2, #32]
        trn1 v30.2d, v6.2d, v7.2d
        trn2 v31.2d, v6.2d, v7.2d
        str q30, [x0, #48]
        str q31, [x2, #48]
        trn1 v30.2d, v8.2d, v9.2d
        trn2 v31.2d, v8.2d, v9.2d
        str q30, [x0, #64]
        str q31, [x2, #64]
        trn1 v30.2d, v10.2d, v11.2d
        trn2 v31.2d, v10.2d, v11.2d
        str q30, [x0, #80]
        str q31, [x2, #80]
        trn1 v30.2d, v12.2d, v13.2d
        trn2 v31.2d, v12.2d, v13.2d
        str q30, [x0, #96]
        str q31, [x2, #96]
        trn1 v30.2d, v14.2d, v15.2d
        trn2 v31.2d, v14.2d, v15.2d
        str q30, [x0, #112]
        str q31, [x2, #112]
        trn1 v30.2d, v16.2d, v17.2d
        trn2 v31.2d, v16.2d, v17.2d
        str q30, [x0, #128]
        str q31, [x2, #128]
        trn1 v30.2d, v18.2d, v19.2d
        trn2 v31.2d, v18.2d, v19.2d
        str q30, [x0, #144]
        str q31, [x2, #144]
        trn1 v30.2d, v20.2d, v21.2d
        trn2 v31.2d, v20.2d, v21.2d
        str q30, [x0, #160]
        str q31, [x2, #160]
        trn1 v30.2d, v22.2d, v23.2d
        trn2 v31.2d, v22.2d, v23.2d
        str q30, [x0, #176]
        str q31, [x2, #176]
        str d24, [x0, #192]
        dup d30, v24.d[1]
        str d30, [x0, #392]
        ldp d10, d11, [sp, #16]
        ldp d12, d13, [sp, #32]
        ldp d14, d15, [sp, #48]
        ldp d8, d9, [sp], #64
        ldp x19, x20, [sp, #64]
        ldp x21, x22, [sp, #80]
        ldp x23, x24, [sp, #96]
        ldp x25, x26, [sp, #112]
        ldp x27, x28, [sp, #128]
        ldr x30, [sp, #144]
        add sp, sp, #160
        ret
