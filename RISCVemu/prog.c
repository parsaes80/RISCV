
int main(void) __attribute__((naked));

int main(void) {
    __asm__ volatile(
        "addi a0, x0, 1\n"
        "addi a1, x0, 1\n"
        "addi a2, x0, 4\n"
        "1:\n"
        "beq a2, x0, 2f\n"
        "add a3, a0, x0\n"
        "add a0, a0, a1\n"
        "add a1, a3, x0\n"
        "addi a2, a2, -1\n"
        "jal x0, 1b\n"
        "2:\n"
        "add a0, a0, a1\n"
        "jalr x0, 0(x1)\n"
    );
    __builtin_unreachable();
}


// volatile int iters = 4;

// int main() {
//     int a = 1, b = 1, temp = 0;

//     for (int i = 0; i < iters; i++) {
//         temp = a;
//         a = a + b;
//         b = temp;
//     }

//     return a + b;
// }