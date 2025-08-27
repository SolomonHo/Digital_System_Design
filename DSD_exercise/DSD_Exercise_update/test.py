import numpy as np

# 給定初始 b
b = np.array([248, -682, 24710, -9624, -3313, 30377, -29996, 30995, -20368, 10952, 5665, 11476, -9108, 7882, 20391, -31505], dtype=float)

n = len(b)

# 初始 x = b/16
x = b 

# 直接一個一個更新 x
for i in range(n):
    xi_minus3 = x[i-3] if 0 <= i-3 < n else 0
    xi_minus2 = x[i-2] if 0 <= i-2 < n else 0
    xi_minus1 = x[i-1] if 0 <= i-1 < n else 0
    xi_plus1  = x[i+1] if 0 <= i+1 < n else 0
    xi_plus2  = x[i+2] if 0 <= i+2 < n else 0
    xi_plus3  = x[i+3] if 0 <= i+3 < n else 0

    # 注意：這裡要暫存舊的 x[i]，因為要用來計算 xi_plus1、xi_plus2 等
    old_xi = x[i]

    x[i] = (51/1024) * (b[i] + 13*(xi_plus1 + xi_minus1) - 6*(xi_plus2 + xi_minus2) + (xi_plus3 + xi_minus3))

hw = x * 65536 

print("正確更新後的 x：")
print(x)
print()
print(hw)
