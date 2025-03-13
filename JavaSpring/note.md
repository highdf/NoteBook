### JavaSpring 的学习笔记

#### Ioc 初步

- 在pom.xml中配置SpringWorkFrame的依赖
- 在src/main/resources目录中创建ApplicationContext.xml配置文件
- ApplicationContext.xml中使用bean标签定义bean

##### bean 的定义
```xml
<bean id="bean的名称" class="bean所实现的类">
    <!-- 使用setField方法来初始化字段 -->
    <!-- bean所实现的类一定要有setField方法 -->
    <!-- 注入的bean一定要存在 -->
    <property name="字段的名称" ref="注入bean的Id"/>
</bean>


