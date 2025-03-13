#### 复用

#### 继承是什么/解决了什么问题/为什么需要它
继承是一种类与类之间的关系。类的继承关系的表现有两种：
- 字段继承：子类会拥有父类的所有字段。因此在子类的内存模型中除了子类本身的字段之外，还有从父类处继承而来的字段
- 方法继承：子类会拥有父类的方法的访间地址。在底层是通过方法表实现。在通过子类对象的引用调用方法时，Java的虚拟机会在其中查找方法
- 是否还存在其他的继承行为呢？

wind
#### 继承与访间修饰符的交互
在Java的继承中，不管是字段继承还是方法继承都不会继承访问修饰符。具体行为由以下代码表达：
```java
package com.luky.extend;

public class Child extends Parent {
	
	@Override
	public String toString() {
		StringBuilder str = new StringBuilder();

		str.append(this.name).append(this.phone.toString()).
		append(this.age.toString()).
		append(this.money.toString());

		return str.toString();
	}
}
```
```java
package com.luky.extend;

public class Parent {
	private String name;
	protected Integer age;
	String phone;
	public Integer money;

	public Parent() {
		this.name = "XinXin";
		this.age = 20;
		this.phone = "12012323432";
		this.money = 2000;
	}
}
```
```java
package com.luky.extend.pack;

import com.luky.extend.Parent;

public class Sister extends Parent {

        @Override
    public String toString() {
                StringBuilder str = new StringBuilder();

                str.append(this.name).append(this.phone.toString()).
        append(this.age.toString()).
        append(this.money.toString());

                return str.toString();
            }
}

```
Child类与Sister类都拥有Parent类的所有字段，但由于访间修饰符是不参与继承。因此部分字段子类无法通过标识符直接访间
